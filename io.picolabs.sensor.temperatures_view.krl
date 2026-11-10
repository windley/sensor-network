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
 * Settings stores an access token and a time zone (PST, MST, CST, or EST)
 * for this browser tab. Mint the token on the temperatures app channel
 * after tagging that channel oauth-webhook. The view shell sends the token
 * as the bearer on latestTemperatures. Reading times use standard time.
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
    // Named explicitly. A null query list is taken from rulesetSchema at
    // install, and an empty list leaves the channel with only xmlui/file.
    // file() then returns null for Main.xmlui.
    app_queries = ["latestTemperatures", "temperatures"]

    /**
     * Format a UTC epoch-millisecond timestamp in a US standard time zone.
     * `time:new` returns an ISO-8601 UTC string. Subtracting the zone's
     * offset first makes the date and clock in that string that zone's time.
     * PST is UTC-8, MST UTC-7, CST UTC-6, EST UTC-5. Anything else is MST.
     * @param timestamp Number milliseconds since the Unix epoch
     * @param zone String "PST, MST, CST, or EST"
     * @returns String "YYYY-MM-DD HH:MM:SS ZZZ"
     */
    readingAtInZone = function(timestamp, zone) {
      name = zone == "PST" => "PST" |
        zone == "CST" => "CST" |
        zone == "EST" => "EST" |
        "MST"
      hours = name == "PST" => 8 |
        name == "CST" => 6 |
        name == "EST" => 5 |
        7
      iso = time:new(timestamp - hours * 60 * 60 * 1000)
      date = iso.split("T")[0]
      clock = iso.split("T")[1].split(".")[0]
      date + " " + clock + " " + name
    }

    /**
     * Latest temperature for each sensor in the linked community.
     * Empty until a relationship with Tx_role "community" is established.
     * @param zone String "PST, MST, CST, or EST. Defaults to MST."
     * @returns Array of { name, lastTemperature, readingAt, timestamp }
     */
    latestTemperatures = function(zone) {
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
        ts.isnull() => row | row.put("readingAt", readingAtInZone(ts, zone))
      })
    }

    /**
     * Community temperatures, refreshed about once a minute.
     * @view "Temperatures"
     */
    temperatures = function() {
      readings_url = ui:query_url("latestTemperatures", meta:rid, meta:eci)
      <<<Component name="Temperatures">
  <DataSource id="readings" url="{'#{readings_url}?zone=' + (sessionStorage.getItem('picoViewZone') || 'MST')}" headers="{appGlobals.auth}" pollIntervalInSeconds="60" />
  <HStack horizontalAlignment="end">
    <Button label="Settings" onClick="viewSettings.open()" />
  </HStack>
  <ModalDialog id="viewSettings" title="Settings">
    <Form saveLabel="Save" onSubmit="(data) => { sessionStorage.setItem('picoViewBearer', (data.bearer || '').trim()); sessionStorage.setItem('picoViewZone', data.zone || 'MST'); location.reload(); }">
      <FormItem bindTo="zone" label="Time zone" type="select" initialValue="{sessionStorage.getItem('picoViewZone') || 'MST'}">
        <Option value="PST" label="PST" />
        <Option value="MST" label="MST" />
        <Option value="CST" label="CST" />
        <Option value="EST" label="EST" />
      </FormItem>
      <FormItem bindTo="bearer" label="Access token" type="password" initialValue="{sessionStorage.getItem('picoViewBearer') || ''}" />
      <Text value="Times use standard time: PST UTC-8, MST UTC-7, CST UTC-6, EST UTC-5. Mint the access token on the temperatures app channel after tagging it oauth-webhook. This browser tab keeps both settings." />
    </Form>
  </ModalDialog>
  <Card title="Temperatures" subtitle="{'Latest reading from each sensor, shown as ' + (sessionStorage.getItem('picoViewZone') || 'MST')}" />
  <Table data="{readings}">
    <Column bindTo="name" header="Sensor" />
    <Column bindTo="lastTemperature" header="Temp (F)" />
    <Column bindTo="readingAt" header="{'Reading at (' + (sessionStorage.getItem('picoViewZone') || 'MST') + ')'}" />
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
    // config allows new_relationship on this channel.
    ui:create_app_channel(channel_tags, ["temperature_view", "config"], app_queries, meta:rid)
  }
}
