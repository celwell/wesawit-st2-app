// Generated by CoffeeScript 1.3.3

Ext.define('WSI.view.EventsList', {
  extend: 'Ext.dataview.List',
  xtype: 'eventslist',
  requires: ['Ext.util.DelayedTask'],
  config: {
    baseCls: 'events-list',
    scrollable: {
      direction: 'vertical',
      directionLock: true,
      indicators: false,
      momentumEasing: {
        momentum: {
          acceleration: 10,
          friction: 0.95
        },
        bounce: {
          acceleration: 30,
          springTension: 0.3
        }
      }
    },
    disableSelection: true,
    pressedCls: false,
    scrollToTopOnRefresh: false,
    loadingText: '',
    emptyText: '',
    listeners: {
      refresh: function(c) {
        return Ext.defer(function() {
          var _ref, _ref1, _ref2;
          if (((_ref = c.getPlugins()[0]) != null ? (_ref1 = _ref.element) != null ? (_ref2 = _ref1.dom) != null ? _ref2.childNodes[1] : void 0 : void 0 : void 0) != null) {
            if (c.getStore().isLoaded() && c.getStore().getCount() === 0) {
              return c.getPlugins()[0].element.dom.childNodes[1].style.display = 'block';
            } else {
              return c.getPlugins()[0].element.dom.childNodes[1].style.display = 'none';
            }
          }
        }, 1000);
      }
    },
    plugins: [
      {
        xclass: 'WSI.plugin.BetterPullRefresh',
        pullRefreshText: 'pull down to refresh',
        releaseRefreshText: 'release to refresh',
        loadingText: 'loading events...',
        pullTpl: ['<div class="x-list-pullrefresh">', '<div class="x-list-pullrefresh-wrap">', '<img src="resources/images/tarsier.png" width="45" height="24" />', '<h3 class="x-list-pullrefresh-message" style="display:none">{message}</h3>', '<div class="x-list-pullrefresh-updated" style="display:none">last updated: <span>{lastUpdated:date("m/d/Y h:iA")}</span></div>', '</div>', '</div>', "<div class='x-list-emptytext' style='display:none;'>{[(navigator.onLine ? 'no events' : 'unable to connect to internet<br />pull down to refresh')]}</div>"].join(''),
        refreshFn: function(plugin) {
          var refresher, store, task;
          if (!navigator.onLine) {
            navigator.notification.alert('Unable to connect to the internet.', (function() {}), 'Oops!');
          } else {
            store = plugin.up().up().getStore();
            refresher = function() {
              store.currentPage = 1;
              return store.load();
            };
            if (!(window.localStorage.getItem('locationTimestamp') != null) || (new Date()) - new Date(window.localStorage.getItem('locationTimestamp')) > 30000) {
              plugin.up().up().fireEvent('grabCurrentPosition');
              task = Ext.create('Ext.util.DelayedTask', refresher);
              task.delay(500);
            } else {
              refresher();
            }
          }
          return false;
        }
      }, {
        xclass: 'Ext.plugin.ListPaging',
        autoPaging: true,
        noMoreRecordsText: "",
        loadMoreText: ''
      }
    ],
    itemTpl: Ext.create('Ext.XTemplate', "<div class=\"list-item-top-cap\">", "{[window.util.calc_time(values.dateTimeStart, values.dateTimeEnd)]}", "{[((distance = window.util.calc_distance(values.locationLat,values.locationLng)) ? \"<div class='distance-away'>\" + distance + \"</div>\" : \"\")]}", "<div class='location-text'>{locationName}</div>", "</div>", "{[(((values.photos.length + values.videos.length > 4 || (new Date()).getTime() - values.dateTimeStart.getTime() < -1800000) && (typeof values.top_photo != 'undefined' || typeof values.top_video != 'undefined')) ? '<div class=\"list-item-thumb\" style=\"background-image: url(' + util.image_url(values, 'medium', true) + ');\"></div>' : '')]}", "<div class=\"list-item-bottom-cap\">", "<div class='title-text'>{title}</div>", "<div class='view-count'>{[window.util.commaize_number(values.viewCount)]} view{[(values.viewCount != 1 ? 's' : '')]}</div>", "<div class='photo-count'>{[window.util.commaize_number(values.num_of_photos)]}</div>", "<div class='video-count'>{[window.util.commaize_number(values.num_of_videos)]}</div>", "</div>", {
      disableFormats: true
    })
  }
});