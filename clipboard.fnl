(require-macros :lib.macros)
(local {:call-when call-when
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

(local log (hs.logger.new "\tclipboard.fnl\t" "debug"))

(local width 50)
(local max-size 30)

(local store-path (.. (os.getenv "HOME") "/.clipboard"))
(local cache-path (.. store-path "/cache.json"))
(local image-path (.. store-path "/images"))

(local UTI_TYPE
    {:IMAGE_TIFF "public.tiff"
     :IMAGE_PNG "public.png"
     :PLAIN_TEXT "public.utf8-plain-text"})

(local HISTORY_TYPE
    {:IMAGE "IMAGE"
     :TEXT "TEXT"})

(fn read-history-from-cache
    []
    (hs.fs.mkdir store-path)
    (if-let [file (io.open cache-path "r")]
        (let [c (: file :read "*l")]
            (: file :close)
            (when c
                ;;(log.d c)
                (hs.json.decode c)))))

(global clipboard-history (or (read-history-from-cache) {}))

(fn save-history-into-cache
    [clipboard-history]
    (if-let [file (io.open cache-path "w")]
        (let [s (hs.json.encode clipboard-history)]
            ;;(log.d "encode: " s)
            (: file :write s)
            (: file :close))))

(fn save-temporary-image
    [image]
    (hs.fs.mkdir image-path)
    (let [b64 (hs.base64.encode (: image :encodeAsURLString))
          start-index (/ (string.len b64) 2)
          end-index (+ start-index 5)
          filename (.. image-path
                       "/"
                       (string.sub b64 start-index end-index)
                       ".png")]
        (: image :saveToFile filename)
        filename))

(fn reduce-history-size
    []
    (while (> (length clipboard-history) max-size)
        (table.remove clipboard-history (length clipboard-history))))

(fn get-uti-item
    [uti]
    (let [item {}]
        (if (or (= uti UTI_TYPE.IMAGE_TIFF)
                (= uti UTI_TYPE.IMAGE_PNG))
            (do
                (tset item :text "_IMAGE_")
                (tset item :type HISTORY_TYPE.IMAGE)
                (tset item :content (save-temporary-image (hs.pasteboard.readImage))))
            (= uti UTI_TYPE.PLAIN_TEXT)
            (do
                (if-let [text (hs.pasteboard.readString)]
                    (when (> (utf8.len text) 3)
                        (tset item :text (string.gsub text "[\r\n]+" " "))
                        (tset item :type HISTORY_TYPE.TEXT)
                        (tset item :content text)))))
        item))

(fn add-history-from-pasteboard
    []
    (local types (hs.pasteboard.contentTypes))
    (let [items (->> types
                     (map get-uti-item)
                     (filter #(~= (_G.next $1) nil)))
          item (. items 1)]
        ;;(each [index v (ipairs items)]
        ;;    (log.df "index: %d, v: %s" index v))
        (if (. item :text)
            (do
               
                (each [index el (ipairs clipboard-history)]
                    (if (= (. item :content)
                           (. el :content))
                        (table.remove clipboard-history index)))
                (tset item :sub-text
                    (.. ;;(. (hs.window.focusedWindow) :application :name)
                        " / "
                        (os.date "%Y-%m-%d %H:%M:%S" (os.time))))
                ;;(log.d "item sub-text:" (. item :sub-text))
                (table.insert clipboard-history 1 item)
                ;;(each [index v (ipairs clipboard-history)]
                ;;    (log.df "history index: %d, v: %s" index v))
                (save-history-into-cache clipboard-history)))))



(fn choice-clipboard
    [choice]
    (when choice
        (if (= (. choice :type) HISTORY_TYPE.IMAGE)
            (-> (hs.image.imageFromPath (. choice :content))
                (hs.pasteboard.writeObjects))
            (hs.pasteboard.setContents (. choice :content)))
        (hs.eventtap.keyStroke ["cmd"] "v"))
    (when (~= "" (: _G.chooser :query))
        (: _G.chooser :query "")))

(global cli-chooser (hs.chooser.new choice-clipboard))

(fn show-clipboard
    []
    ;;(log.d "history:" clipboard-history)
    ;;(each [index v (ipairs clipboard-history)]
    ;;    (log.df "history index: %d, v: %s" index v))
    (let [map-fn
          (fn [item]
            (let [choice (hs.fnutils.copy item)]
                (tset choice :text (.. " " item.text))
                (tset choice :sub-text (.. " " item.sub-text))
                (when (= item.type HISTORY_TYPE.IMAGE)
                    (tset choice :image (hs.image.imageFromPath item.content)))
                choice))
          choices (map map-fn clipboard-history)]
        (: cli-chooser :width width)
        (: cli-chooser :bgDark false)
        (: cli-chooser :choices choices)
        (: cli-chooser :show)))

(var pre-change-count (hs.pasteboard.changeCount))

(global clipboard-watcher
    (hs.timer.new
        0.5
        (fn []
            (let [change-count (hs.pasteboard.changeCount)]
                (when (~= pre-change-count change-count)
                (log.d "change count:" change-count)
                    (pcall add-history-from-pasteboard)
                    (set pre-change-count change-count))))))

(: clipboard-watcher :start)

(hs.hotkey.bind ["cmd" "shift"] "v" show-clipboard)
