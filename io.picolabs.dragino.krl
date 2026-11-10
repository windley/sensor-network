ruleset io.picolabs.dragino {
    meta {
        name "Dragino Module"
        description "Provides functions for using Dragino devices"
        author "PJW"
        version "0.1.1"
        provides get_payload, cToF, fix_temperatures, get_battery_status, get_battery_value
        shares get_payload, cToF, fix_temperatures, get_battery_status, get_battery_value
    }

    global {

        /**
         * Celsius to Fahrenheit, two decimal places.
         * @param c Number "temperature in Celsius"
         * @returns Number
         */
        cToF = function(c){math:int(c*180+3200)/100}; // two decimal places

        /**
         * Signed Dragino temperature counts to Celsius.
         * LSN50 uses a divisor of 10; other sensors use 100.
         * @param x Number "raw count from the payload"
         * @param sensor String "lht65, lse01, ldds20, lsn50, or wl03a"
         * @returns Number
         */
        fix_temperatures = function(x, sensor = "lht65") {
            divisor = (sensor == "lsn50") => 10
                    | 100
            math:int(x < 32768 => x | x-65536)/divisor
        }; 

        /**
         * Decode a base64 Dragino payload into numeric fields.
         * @param sensor String "lht65, lse01, ldds20, lsn50, wl03a_lb_status, or wl03a_lb_data"
         * @param payload String "base64 payload"
         * @returns Array
         */
        get_payload = function(sensor, payload){
            decoded = math:base64decode(payload,"hex") // .klog("Decoded");
            split = (sensor == "lht65") => decoded.extract(re#(.{4})(.{4})(.{4})(.{2})(.{4})(.{4})#).klog("LHT65")
                  | (sensor == "lse01") => decoded.extract(re#(.{4})(.{4})(.{4})(.{4})(.{4})(.{2})#)
                  | (sensor == "ldds20") => decoded.extract(re#(.{4})(.{4})(.{2})(.{4})(.{2})#)
                  | (sensor == "lsn50") => decoded.extract(re#(.{4})(.{4})(.{4})(.{2})(.{4})(.{4})#)
                  | (sensor == "wl03a_lb_status") => decoded.extract(re#(.{2})(.{4})(.{2})(.{2})(.{4})#)
                  | (sensor == "wl03a_lb_data") => decoded.extract(re#(.{2})(.{6})(.{6})(.{8})#)
                  | [];
            payload_array = split.map(function(x){("0x"+ x).as("Number")}) //.klog("Values") 
            return payload_array 
        }
        
        /**
         * Battery status from the first payload field: ultra_low, low, ok, or good.
         * @param sensor String "sensor type; the status bits are in the same place for current devices"
         * @param payload Array "decoded payload from get_payload"
         * @returns String
         */
        get_battery_status = function(sensor, payload){
            // sensor unused unless battery status is in different places on different sensor types
            status_value = payload[0].shiftRight(14)
            statuses = ["ultra_low", "low", "ok", "good"]
            statuses[status_value] //.klog("Battery status")
        }
        /**
         * Battery voltage in millivolts from the first payload field.
         * @param sensor String "sensor type; the voltage bits are in the same place for current devices"
         * @param payload Array "decoded payload from get_payload"
         * @returns Number
         */
        get_battery_value = function(sensor, payload){
            // sensor unused unless battery status is in different places on different sensor types
            payload[0].band("0x3FFF") //.klog("Battery voltage (mV)")
        }
    }
}