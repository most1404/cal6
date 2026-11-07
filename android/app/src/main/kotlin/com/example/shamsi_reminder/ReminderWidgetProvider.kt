package com.example.shamsi_reminder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

class ReminderWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.reminder_widget_layout).apply {
                // Dynamic font size settings: "small" (12sp), "medium" (14sp), "large" (17sp)
                val fontSize = widgetData.getString("widget_font_size", "medium") ?: "medium"
                val textSizeSp = when (fontSize) {
                    "small" -> 12f
                    "large" -> 17f
                    else -> 14f
                }

                val title = widgetData.getString("widget_header_title", "یادآورهای فعال")
                val date = widgetData.getString("widget_shamsi_date", "")

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_date, date)

                setTextViewTextSize(R.id.widget_title, android.util.TypedValue.COMPLEX_UNIT_SP, textSizeSp + 2f)
                setTextViewTextSize(R.id.widget_date, android.util.TypedValue.COMPLEX_UNIT_SP, textSizeSp - 2f)

                // Wire prominent Green "+" Button to launch Add Reminder in App
                val addIntent = Intent(context, MainActivity::class.java).apply {
                    action = "ACTION_ADD_REMINDER"
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingAdd = PendingIntent.getActivity(
                    context,
                    1001,
                    addIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_add_button, pendingAdd)

                // Wire dynamic ListView to ReminderListWidgetService
                val serviceIntent = Intent(context, ReminderListWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                setRemoteAdapter(R.id.widget_reminders_list, serviceIntent)
                setEmptyView(R.id.widget_reminders_list, R.id.widget_empty_text)

                // PendingIntent template for clicking on individual reminder cards
                val clickIntent = Intent(context, MainActivity::class.java)
                val pendingClick = PendingIntent.getActivity(
                    context,
                    1002,
                    clickIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                )
                setPendingIntentTemplate(R.id.widget_reminders_list, pendingClick)
            }

            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_reminders_list)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

/**
 * Service to supply RemoteViews to ListView in Android Widget
 */
class ReminderListWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ReminderListRemoteViewsFactory(this.applicationContext, intent)
    }
}

class ReminderListRemoteViewsFactory(
    private val context: Context,
    intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private val items = ArrayList<JSONObject>()

    override fun onCreate() {
        loadData()
    }

    override fun onDataSetChanged() {
        loadData()
    }

    private fun loadData() {
        items.clear()
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val rawJson = prefs.getString("flutter.widget_reminders_json", null)
            ?: prefs.getString("widget_reminders_json", null)

        if (!rawJson.isNullOrEmpty()) {
            try {
                val jsonArray = JSONArray(rawJson)
                for (i in 0 until jsonArray.length()) {
                    items.add(jsonArray.getJSONObject(i))
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onDestroy() {
        items.clear()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews? {
        if (position < 0 || position >= items.size) return null

        val item = items[position]
        val rv = RemoteViews(context.packageName, R.layout.reminder_widget_item)

        val title = item.optString("title", "")
        val time = item.optString("time", "")

        rv.setTextViewText(R.id.widget_item_title, title)
        if (time.isNotEmpty()) {
            rv.setTextViewText(R.id.widget_item_time, time)
            rv.setViewVisibility(R.id.widget_item_time, View.VISIBLE)
        } else {
            rv.setViewVisibility(R.id.widget_item_time, View.GONE)
        }

        val fillInIntent = Intent().apply {
            putExtra("reminder_id", item.optString("id", ""))
        }
        rv.setOnClickFillInIntent(R.id.widget_item_container, fillInIntent)

        return rv
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
}
