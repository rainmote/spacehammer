(require-macros :lib.macros)
(local {:contains? contains?
        :call-when call-when
        :concat    concat
        :find      find
        :filter    filter
        :get       get
        :has-some? has-some?
        :join      join
        :last      last
        :map       map
        :merge     merge
        :noop      noop
        :slice     slice
        :tap       tap}
       (require :lib.functional))

(local log (hs.logger.new "\tworking.fnl\t" "debug"))

(local work-wifi-list ["alibaba-inc"])
(local route-list
  ["47.102.254.229"
   "47.102.10.20"
   "106.15.153.100"
   "47.102.252.66"
   "139.196.2.192"
   "106.15.161.144"])

(global wifi-watcher
  (hs.wifi.watcher.new
    (fn []
      (let [cur-wifi (hs.wifi.currentNetwork)
            ali-gateway (io.popen "netstat -nr|grep 106.11/16 | awk '{print $2}'")]
        (when (and (not (contains? cur-wifi work-wifi-list))
                   cur-wifi
                   ali-gateway)
          (log.df "current wifi: %s, need add route" cur-wifi)
          (each [index v (ipairs route-list)]
            (io.popen (.. "netstat -nr | grep -q "
                          v
                          " || sudo route -n add "
                          v
                          " "
                          ali-gateway))))))))

(: wifi-watcher :start)



