/*
 * Copyright (c) 2013, WeSawIt Inc.
 * Author: celwell
 * Some parts originally from Cordova Project and under Apache License
 */

package com.phonegap.plugins.actionSheet;


import java.util.ArrayList;

import org.apache.cordova.api.CallbackContext;
import org.apache.cordova.api.CordovaPlugin;
import org.apache.cordova.api.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.util.Log;

public class ActionSheet extends CordovaPlugin  {

    protected static final String LOG_TAG = "ActionSheet";

    private CallbackContext callbackContext;
    
    /**
     * Executes the request and returns PluginResult.
     *
     * @param action        The action to execute.
     * @param args          JSONArry of arguments for the plugin.
     * @param callbackId    The callback id used when calling back into JavaScript.
     * @return              A PluginResult object with a status and message.
     */
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
    	
    	this.callbackContext = callbackContext;
    	
    	Log.d(LOG_TAG, "action = " + action);
    	Log.d(LOG_TAG, "args = " + args);
    	
        if (action.equals("create")) {
            ArrayList<String> choices = new ArrayList<String>();
            
            String title = args.getJSONObject(0).getString("title");
            JSONArray items = args.getJSONObject(0).getJSONArray("items");
            
            for(int i = 0, count = items.length(); i < count; i++) {
            	Log.d(LOG_TAG, "in loop: " + i);
                choices.add(items.get(i).toString());
            }
            
            Log.d(LOG_TAG, "choices = " + choices);
            
            AlertDialog.Builder builder = new AlertDialog.Builder(cordova.getActivity());
    	    Log.d(LOG_TAG, "after new AlertDialog");
    	    builder.setTitle(title);
    	    Log.d(LOG_TAG, "after builder set title");
    	    CharSequence[] choicesAsCharSeq = choices.toArray(new CharSequence[choices.size()]);
    	    builder.setItems(choicesAsCharSeq, new DialogInterface.OnClickListener() {
    	    	public void onClick(DialogInterface dialog, int which) {
    	    		// The 'which' argument contains the index position
    	    		// of the selected item
    	    		Log.d(LOG_TAG, "Index #" + which + " chosen.");
    	    		JSONObject message = new JSONObject();
    	    		try {
						message.put("buttonIndex", which);
					} catch (JSONException e) {
						Log.d(LOG_TAG, e.getStackTrace().toString());
					}
    	    		Log.d(LOG_TAG, "before response sent");
    	    		ActionSheet.this.callbackContext.success(message);
    	    		Log.d(LOG_TAG, "after response sent");
		       }
    	    });
    	    Log.d(LOG_TAG, "after builder set items");
    	    builder.show();
    	    Log.d(LOG_TAG, "after builder show");
        }
        
        return true;
    }
    
}
