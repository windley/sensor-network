/**
 * Temperature display for one sensor community.
 *
 * Install on a pico created for this page, along with `io.picolabs.xmlui`.
 * Do not install it on the community or on a sensor thing.
 *
 * Raise `config new_relationship` with `webvh` set to the community pico's
 * did:webvh. This pico sends a Layer 2 invite: its role is `temperature_view`
 * and the community's role is `community`. Approve the invite on the community.
 * The page reads `lastTemperatures` over that relationship. The role is not
 * `thing`, so the community does not treat this pico as a sensor.
 *
 * Open `/ui/<app-eci>/io.picolabs.sensor.temperatures_view/`.
 */
ruleset io.picolabs.sensor.temperatures_view {
  meta {
    name "Temperature view"
    description "XMLUI page of a community's latest sensor temperatures"
    author "PJW"

    use module io.picolabs.subscription alias subscription
    use module io.picolabs.xmlui alias ui

    shares latestTemperatures, temperatures
  }

  global {
    community_rid = "io.picolabs.sensor.community"
    community_role = "community"
    view_role = "temperature_view"
    channel_tags = ["temperatures_view", "app"]

    /**
     * Format a UTC epoch-millisecond timestamp as Mountain Standard Time.
     * `time:new` returns an ISO-8601 UTC string. Subtracting the offset first
     * makes the date and clock in that string the MST reading time.
     * @param timestamp Number milliseconds since the Unix epoch
     * @returns String "YYYY-MM-DD HH:MM:SS MST"
     */
    readingAtMst = function(timestamp) {
      mst_offset_ms = 7 * 60 * 60 * 1000
      iso = time:new(timestamp - mst_offset_ms)
      date = iso.split("T")[0]
      clock = iso.split("T")[1].split(".")[0]
      date + " " + clock + " MST"
    }

    /**
     * Latest temperature for each sensor in the linked community.
     * Empty until a relationship with Tx_role "community" is established.
     * @returns Array of { name, lastTemperature, readingAt, timestamp }
     */
    latestTemperatures = function() {
      bus = subscription:established("Tx_role", community_role).head()
      rows = bus.isnull() => [] |
        subscription:queryOnSub(
          bus{"Id"},
          community_rid,
          "lastTemperatures",
          {}
        )
      list = rows.isnull() => [] |
        rows.typeof() == "Array" => rows | []
      list.map(function(row) {
        ts = row{"timestamp"}
        ts.isnull() => row | row.put("readingAt", readingAtMst(ts))
      })
    }

    /**
     * Community temperatures, refreshed about once a minute.
     * @view "Temperatures"
     */
    temperatures = function() {
      source = "<DataSource id=\"readings\" url=\"" +
        ui:query_url("latestTemperatures", meta:rid, meta:eci) +
        "\" headers=\"{appGlobals.auth}\" pollIntervalInSeconds=\"60\" />"
      <<<Component name="Temperatures">
  #{source}
  <Card title="Temperatures" subtitle="Latest reading from each sensor, shown as MST" />
  <Table data="{readings}">
    <Column bindTo="name" header="Sensor" />
    <Column bindTo="lastTemperature" header="Temp (F)" />
    <Column bindTo="readingAt" header="Reading at (MST)" />
  </Table>
</Component>
>>
    }
  }

  /**
   * Invite the sensor community identified by webvh.
   * The invite stays outbound until the community approves it.
   * @attr webvh String "the community pico's did:webvh"
   * @example "community" { "webvh": "did:webvh:example" }
   */
  rule invite_community {
    select when config new_relationship
    pre {
      webvh = event:attr("webvh")
    }
    if webvh then noop()
    fired {
      raise wrangler event "subscription" attributes {
        "layer2": true,
        "target_did": webvh,
        "name": "temperature view",
        "Rx_role": view_role,
        "Tx_role": community_role
      }
    }
  }

  rule create_app_channel {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    // queries null allows every shared function, including the @view query.
    // config allows new_relationship on this channel.
    ui:create_app_channel(channel_tags, ["temperature_view", "config"], null, meta:rid)
  }
}
