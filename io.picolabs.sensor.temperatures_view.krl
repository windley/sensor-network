/**
 * Temperature display for one sensor community.
 *
 * Install on a pico created for this page, along with `io.picolabs.xmlui`.
 * Do not install it on the community or on a sensor thing.
 *
 * From this pico, request a relationship to the community
 * (`wrangler` event `subscription`) with `Rx_role` `temperature_view` and
 * `Tx_role` `community`, then approve it on the community. The page reads
 * `lastTemperatures` over that relationship. The role is not `thing`, so the
 * community does not treat this pico as a sensor.
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

  rule create_app_channel {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    // queries null allows every shared function, including the @view query.
    ui:create_app_channel(channel_tags, ["temperature_view"], null, meta:rid)
  }
}
