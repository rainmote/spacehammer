(hs.console.clearConsole)
(hs.ipc.cliInstall) ; ensure CLI installed

;;;;;;;;;;;;;;
;; defaults ;;
;;;;;;;;;;;;;;

(set hs.hints.style :vimperator)
(set hs.hints.showTitleThresh 4)
(set hs.hints.titleMaxSize 10)
(set hs.hints.fontSize 30)
(set hs.window.animationDuration 0.2)

(global alert hs.alert.show)
(global log (fn [s] (hs.alert.show (hs.inspect s) 5)))
(global fw hs.window.focusedWindow)

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  auto reload config   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
(global
 config-file-pathwatcher
 (hs.pathwatcher.new
  hs.configdir
  (fn [files]
    (let [u hs.fnutils
          fnl-file-change? (u.some
                            files,
                            (fn [p]
                              (let [ext (u.split p "%p")]
                                (or (u.contains ext "fnl")
                                    (u.contains ext "lua")))))]
      (when fnl-file-change? (hs.reload))))))

(: config-file-pathwatcher :start)


;;;;;;;;;;;;
;; modals ;;
;;;;;;;;;;;;
(local modal (require "modal"))

(each [_ n (pairs [:windows :apps :multimedia :emacs])]
  (let [module (require n)]
    (when module.addState
      (module.addState modal))))


(let [state-machine (modal.createMachine)]
  (: state-machine :toMain))