ruleset io.picolabs.iotplotter {
  meta {

    name "iot_plotter"
    author "PJW"
    description "Sends data to IotPlotter API"
    version "0.3.0"

    use module io.picolabs.wrangler alias wrangler

    shares show_configuration, README

  }

  global {
 
    // map readings into format needed by IoTPlotter, removing any items with keys in `remove_these`
    format_payload = function(event_attrs) {
      remove_these = ["battery_status"];
      payload_data = event_attrs{["readings"]}
                         .map(function(reading_val){
                             [
                              {"value": reading_val,
                               "epoch": event_attrs{["timestamp"]}
                              }
                             ]})
                         .filter(function(v, k){not(remove_these >< k)}) 
                         //.klog("New reading map");
      payload_data
    };

    send_payload = defaction(feed_id, api_key, event_attrs) {
      http:post("http://iotplotter.com/api/v2/feed/" + feed_id,
         headers = {"api-key": api_key},
         json = {"data": format_payload(event_attrs)}
      ) setting(resp);
      return resp
    }

    /**
     * Effective IoTPlotter feed. Ruleset config wins, then entity variables.
     * @returns Map
     */
    show_configuration = function() {
      return {"api_key": meta:rulesetConfig{["api_key"]} || ent:api_key,
              "feed_id": meta:rulesetConfig{["feed_id"]} || ent:feed_id}
    }

    /**
     * Note on entering a feed id in the developer UI.
     * @returns String
     */
    README = function() {
      return <<
IoTPlotter feed_id's are just digits. The pico enginer UI will parse them as INTs (using JSON.parse()) unless you enclose them in quotes (e.g. "367832564114515476")
>>
    }

  }

  rule send_data_to_IoTPlotter {
    select when sensor new_readings
    pre {
      config = show_configuration();
      feed_id = config{"feed_id"};
      api_key = config{"api_key"};
    }
    // only send to IoTPlotter when configured; skip if either value is missing
    if not (feed_id.isnull() || api_key.isnull()) then
      send_payload(feed_id, api_key, event:attrs) setting(resp)

    fired {
      response =  resp.klog("POST response");
    }
  }

  /**
   * Store the IoTPlotter feed id and API key on this pico.
   * Quote the feed id in the testing tab so it stays a string.
   * @attr iotplotter_feed_id String "feed id digits"
   * @attr iotplotter_api_key String "IoTPlotter API key"
   * @example "feed" { "iotplotter_feed_id": "367832564114515476", "iotplotter_api_key": "replace-me" }
   */
  rule save_config {
    select when sensor configuration
    pre {
      feed_id = event:attr("iotplotter_feed_id").klog("Feed ID input: ");
      api_key = event:attr("iotplotter_api_key");
    }
    if not (feed_id.isnull() || api_key.isnull()) then noop()
    fired {
      log info "Configuring IoT Plotter";
      ent:feed_id := feed_id.klog("Feed ID saved: ");
      ent:api_key := api_key;
    }
  }

}