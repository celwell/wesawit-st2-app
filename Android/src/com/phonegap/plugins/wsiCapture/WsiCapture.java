/*
 * Copyright (c) 2013, WeSawIt Inc.
 * Author: celwell
 * Some parts originally from Cordova Project and under Apache License
 */

package com.phonegap.plugins.wsiCapture;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import org.apache.cordova.api.CallbackContext;
import org.apache.cordova.api.CordovaInterface;
import org.apache.cordova.api.CordovaPlugin;
import org.apache.cordova.api.LOG;
import org.apache.cordova.api.PluginResult;
import org.apache.cordova.FileUtils;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.services.s3.AmazonS3Client;
import com.amazonaws.services.s3.model.CannedAccessControlList;
import com.amazonaws.services.s3.model.PutObjectRequest;
import com.amazonaws.services.s3.model.PutObjectResult;
import com.phonegap.plugins.wsiCameraLauncher.WsiCameraLauncher;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ContentValues;
import android.content.DialogInterface;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.media.MediaPlayer;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;
import android.view.KeyEvent;
import android.content.Context;
import android.content.pm.ActivityInfo;

public class WsiCapture extends CordovaPlugin {

	private static final String VIDEO_3GPP = "video/3gpp";
	private static final String VIDEO_MP4 = "video/mp4";
	private static final String AUDIO_3GPP = "audio/3gpp";
	private static final String IMAGE_JPEG = "image/jpeg";

	private static final int CAPTURE_AUDIO = 0; // Constant for capture audio
	private static final int CAPTURE_IMAGE = 1; // Constant for capture image
	private static final int CAPTURE_VIDEO = 2; // Constant for capture video
	private static final String LOG_TAG = "WsiCapture";

	private static final int CAPTURE_INTERNAL_ERR = 0;
	// private static final int CAPTURE_APPLICATION_BUSY = 1;
	// private static final int CAPTURE_INVALID_ARGUMENT = 2;
	private static final int CAPTURE_NO_MEDIA_FILES = 3;

	private CallbackContext callbackContext; // The callback context from which
												// we were invoked.
	private long limit; // the number of pics/vids/clips to take
	private double duration; // optional duration parameter for video recording
	private JSONArray results; // The array of results to be returned to the
								// user
	private int numPics; // Number of pictures before capture activity

	// private CordovaInterface cordova;

	// public void setContext(Context mCtx)
	// {
	// if (CordovaInterface.class.isInstance(mCtx))
	// cordova = (CordovaInterface) mCtx;
	// else
	// LOG.d(LOG_TAG,
	// "ERROR: You must use the CordovaInterface for this to work correctly. Please implement it in your activity");
	// }

	@Override
	public boolean execute(String action, JSONArray args,
			CallbackContext callbackContext) throws JSONException {
		this.callbackContext = callbackContext;
		this.limit = 1;
		this.duration = 0.0f;
		this.results = new JSONArray();
		
		Log.d(LOG_TAG, "wsiCapture execute called");

		JSONObject options = args.optJSONObject(0);
		if (options != null) {
			limit = options.optLong("limit", 1);
			duration = options.optDouble("duration", 0.0f);
		}

		if (action.equals("getFormatData")) {
			JSONObject obj = getFormatData(args.getString(0), args.getString(1));
			callbackContext.success(obj);
			return true;
		} else if (action.equals("captureAudio")) {
			this.captureAudio();
		} else if (action.equals("captureImage")) {
			this.captureImage();
		} else if (action.equals("captureVideo")) {
			this.captureVideo(duration);
		} else {
			return false;
		}

		return true;
	}

	/**
	 * Provides the media data file data depending on it's mime type
	 * 
	 * @param filePath
	 *            path to the file
	 * @param mimeType
	 *            of the file
	 * @return a MediaFileData object
	 */
	private JSONObject getFormatData(String filePath, String mimeType)
			throws JSONException {
		JSONObject obj = new JSONObject();
		// setup defaults
		obj.put("height", 0);
		obj.put("width", 0);
		obj.put("bitrate", 0);
		obj.put("duration", 0);
		obj.put("codecs", "");

		// If the mimeType isn't set the rest will fail
		// so let's see if we can determine it.
		if (mimeType == null || mimeType.equals("") || "null".equals(mimeType)) {
			mimeType = FileUtils.getMimeType(filePath);
		}
		//Log.d(LOG_TAG, "Mime type = " + mimeType);

		if (mimeType.equals(IMAGE_JPEG) || filePath.endsWith(".jpg")) {
			obj = getImageData(filePath, obj);
		} else if (mimeType.endsWith(AUDIO_3GPP)) {
			obj = getAudioVideoData(filePath, obj, false);
		} else if (mimeType.equals(VIDEO_3GPP) || mimeType.equals(VIDEO_MP4)) {
			obj = getAudioVideoData(filePath, obj, true);
		}
		return obj;
	}

	/**
	 * Get the Image specific attributes
	 * 
	 * @param filePath
	 *            path to the file
	 * @param obj
	 *            represents the Media File Data
	 * @return a JSONObject that represents the Media File Data
	 * @throws JSONException
	 */
	private JSONObject getImageData(String filePath, JSONObject obj)
			throws JSONException {
		BitmapFactory.Options options = new BitmapFactory.Options();
		options.inJustDecodeBounds = true;
		BitmapFactory
				.decodeFile(FileUtils.stripFileProtocol(filePath), options);
		obj.put("height", options.outHeight);
		obj.put("width", options.outWidth);
		return obj;
	}

	/**
	 * Get the Image specific attributes
	 * 
	 * @param filePath
	 *            path to the file
	 * @param obj
	 *            represents the Media File Data
	 * @param video
	 *            if true get video attributes as well
	 * @return a JSONObject that represents the Media File Data
	 * @throws JSONException
	 */
	private JSONObject getAudioVideoData(String filePath, JSONObject obj,
			boolean video) throws JSONException {
		MediaPlayer player = new MediaPlayer();
		try {
			player.setDataSource(filePath);
			player.prepare();
			obj.put("duration", player.getDuration() / 1000);
			if (video) {
				obj.put("height", player.getVideoHeight());
				obj.put("width", player.getVideoWidth());
			}
		} catch (IOException e) {
			Log.d(LOG_TAG, "Error: loading video file");
		}
		return obj;
	}

	/**
	 * Sets up an intent to capture audio. Result handled by onActivityResult()
	 */
	private void captureAudio() {
		Intent intent = new Intent(
				android.provider.MediaStore.Audio.Media.RECORD_SOUND_ACTION);

		this.cordova.startActivityForResult((CordovaPlugin) this, intent,
				CAPTURE_AUDIO);
	}

	/**
	 * Sets up an intent to capture images. Result handled by onActivityResult()
	 */
	private void captureImage() {
		// Save the number of images currently on disk for later
		this.numPics = queryImgDB(whichContentStore()).getCount();

		Intent intent = new Intent(
				android.provider.MediaStore.ACTION_IMAGE_CAPTURE);

		// Specify file so that large image is captured and returned
		File photo = new File(
			this.getTempDirectoryPath(this.cordova.getActivity()), "Capture.jpg"
		);
		intent.putExtra(android.provider.MediaStore.EXTRA_OUTPUT, Uri.fromFile(photo));
		

		this.cordova.startActivityForResult((CordovaPlugin) this, intent,
				CAPTURE_IMAGE);		
	}
	
	private String getTempDirectoryPath(Context ctx) {
		File cache = null;

        // SD Card Mounted
        if (Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED)) {
            cache = new File(Environment.getExternalStorageDirectory().getAbsolutePath() +
                    "/Android/data/" + ctx.getPackageName() + "/cache/");
        }
        // Use internal storage
        else {
            cache = ctx.getCacheDir();
        }

        // Create the cache directory if it doesn't exist
        if (!cache.exists()) {
            cache.mkdirs();
        }

        return cache.getAbsolutePath();
	}

	/**
	 * Sets up an intent to capture video. Result handled by onActivityResult()
	 */
	private void captureVideo(double duration) {
		Log.d(LOG_TAG, "CaptureVideo called.");
		
		// Save the number of images currently on disk for later
		this.numPics = queryImgDB(whichContentStore()).getCount();
		
		final File photo = new File(
			this.getTempDirectoryPath(this.cordova.getActivity()), "Capture.jpg"
		);
		
	    String[] choices = {"Take a Photo", "Take a Video"};
	    
	    AlertDialog.Builder builder = new AlertDialog.Builder(this.cordova.getActivity());
	    builder.setItems(choices, new DialogInterface.OnClickListener() {
	           public void onClick(DialogInterface dialog, int which) {
				   //Log.d(LOG_TAG, "Index #" + which + " chosen.");
				   if (which == 0) {
						// set up photo intent
						final Intent cameraIntent = new Intent(
								android.provider.MediaStore.ACTION_IMAGE_CAPTURE);
						cameraIntent.putExtra(android.provider.MediaStore.EXTRA_SCREEN_ORIENTATION, ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE); // this isn't doing anything
						cameraIntent.putExtra(MediaStore.EXTRA_SHOW_ACTION_ICONS, false);
						cameraIntent.putExtra(android.provider.MediaStore.EXTRA_OUTPUT, Uri.fromFile(photo));
						WsiCapture.this.cordova.startActivityForResult((CordovaPlugin) WsiCapture.this, cameraIntent, CAPTURE_IMAGE);
	        	   } else if (which == 1) {
	        		   // set up video intent
	        		   Intent videoIntent = new Intent(android.provider.MediaStore.ACTION_VIDEO_CAPTURE);
	        		   videoIntent.putExtra(android.provider.MediaStore.EXTRA_SCREEN_ORIENTATION, ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE); // this isn't doing anything
	        		   videoIntent.putExtra(android.provider.MediaStore.EXTRA_VIDEO_QUALITY, 0);
	        		   videoIntent.putExtra(MediaStore.EXTRA_SHOW_ACTION_ICONS, false);
	        		   videoIntent.putExtra(MediaStore.EXTRA_DURATION_LIMIT, 300); // 300 secs -- 5 minutes
	        		   WsiCapture.this.cordova.startActivityForResult((CordovaPlugin) WsiCapture.this, videoIntent, CAPTURE_VIDEO);
	        	   } else {
	        		   return;
	        	   }
	           }
	       });
	    builder.setOnKeyListener(new DialogInterface.OnKeyListener() {
	        @Override
	        public boolean onKey (DialogInterface dialog, int keyCode, KeyEvent event) {
	            if (keyCode == KeyEvent.KEYCODE_BACK && 
	                event.getAction() == KeyEvent.ACTION_UP && 
	                !event.isCanceled()) {
	                dialog.cancel();
	                WsiCapture.this.fail(createErrorObject(CAPTURE_NO_MEDIA_FILES, "Canceled."));
	                return true;
	            }
	            return false;
	        }
	    });
	    builder.show();
	}

	
	
	private class UploadFilesToS3Task extends AsyncTask<Object, Void, PutObjectResult> {
	
		private Exception exception;
		private CallbackContext callbackContext;
		
		private String mid;
		private JSONObject mediaFile;
	
		protected PutObjectResult doInBackground(Object... params) {
		    try {
		    	//Log.d(LOG_TAG, "Inside doInBackground.");
		    	File fileToUpload = (File)params[0];
		    	File fileToUploadMedium = (File)params[1];
		    	File fileToUploadThumb = (File)params[2];
		        this.callbackContext = (CallbackContext)params[3];
		        this.mid = (String)params[4];
		        this.mediaFile = (JSONObject)params[5];
				AmazonS3Client s3Client = new AmazonS3Client( new BasicAWSCredentials( "---AWS KEY REMOVED---", "---AWS SECRET KEY REMOVED---" ) );
				//Log..d(LOG_TAG, "mid = " + mid);
				
				PutObjectRequest por = new PutObjectRequest( "---AWS BUCKET NAME REMOVED---", "econ_" + mid + ".jpg", fileToUpload );
				por.setCannedAcl(CannedAccessControlList.PublicRead);
				//Log.d(LOG_TAG, "about to PUT");
				PutObjectResult result = s3Client.putObject(por);
				//Log.d(LOG_TAG, "After PUT");
				
				PutObjectRequest porMedium = new PutObjectRequest( "---AWS BUCKET NAME REMOVED---", "medium_" + mid + ".jpg", fileToUploadMedium );
				porMedium.setCannedAcl(CannedAccessControlList.PublicRead);
				//Log.d(LOG_TAG, "about to PUT porMedium");
				PutObjectResult resultMedium = s3Client.putObject(porMedium);
				//Log.d(LOG_TAG, "After PUT porMedium");
				
				PutObjectRequest porThumb = new PutObjectRequest( "---AWS BUCKET NAME REMOVED---", "thumb_" + mid + ".jpg", fileToUploadThumb );
				porThumb.setCannedAcl(CannedAccessControlList.PublicRead);
				//Log.d(LOG_TAG, "about to PUT porThumb");
				PutObjectResult resultThumb = s3Client.putObject(porThumb);
				//Log.d(LOG_TAG, "After PUT porThumb");
				
		        return result;
		    } catch (Exception e) {
		        this.exception = e;
		        Log.d(LOG_TAG, "exception in doInBackground catch: " + this.exception.toString());
		        return null;
		    }
		}
		
		protected void onPostExecute(PutObjectResult result) {
			//Log.d(LOG_TAG, "Inside onPostExecute.");
			if (result != null) {
				// was successful upload
				//Log.d(LOG_TAG, "result of put: " + result.toString());
				try {
					mediaFile.put("status", "loaded");
					mediaFile.put("statusMedium", "loaded");
					mediaFile.put("statusThumb", "loaded");
					mediaFile.put("typeOfPluginResult", "success");
					PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, (new JSONArray()).put(mediaFile));
					pluginResult.setKeepCallback(false);
					this.callbackContext.sendPluginResult(pluginResult);
				} catch (JSONException e) {
					Log.d(LOG_TAG, "error: " + e.getStackTrace().toString());
				}
			} else {
				if (this.exception != null) {
					Log.d(LOG_TAG, "exception in asynctask if any: " + this.exception.toString());
				}
			}
		}
	}
	
	
	private class UploadVideoToS3Task extends AsyncTask<Object, Void, PutObjectResult> {
		
		private Exception exception;
		private CallbackContext callbackContext;
		
		private String mid;
		private JSONObject mediaFile;
	
		protected PutObjectResult doInBackground(Object... params) {
		    try {
		    	File fileToUpload = (File)params[0];
		        this.callbackContext = (CallbackContext)params[1];
		        this.mid = (String)params[2];
		        this.mediaFile = (JSONObject)params[3];
		        
				AmazonS3Client s3Client = new AmazonS3Client( new BasicAWSCredentials( "---AWS KEY REMOVED---", "---AWS SECRET KEY REMOVED---" ) );
				
				PutObjectRequest por = new PutObjectRequest( "---AWS BUCKET NAME REMOVED---", "" + mid + "." + mediaFile.getString("fileExt"), fileToUpload );
				por.setCannedAcl(CannedAccessControlList.PublicRead);
				Log.d(LOG_TAG, "about to PUT video");
				PutObjectResult result = s3Client.putObject(por);
				Log.d(LOG_TAG, "After PUT video");
				
		        return result;
		    } catch (Exception e) {
		        this.exception = e;
		        Log.d(LOG_TAG, "exception in doInBackground catch: " + this.exception.toString());
		        return null;
		    }
		}
		
		protected void onPostExecute(PutObjectResult result) {
			//Log.d(LOG_TAG, "Inside onPostExecute.");
			if (result != null) {
				// was successful upload
				//Log.d(LOG_TAG, "result of put: " + result.toString());
				try {
					mediaFile.put("status", "loaded");
					mediaFile.put("typeOfPluginResult", "success");
					PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, (new JSONArray()).put(mediaFile));
					pluginResult.setKeepCallback(false);
					this.callbackContext.sendPluginResult(pluginResult);
				} catch (JSONException e) {
					Log.d(LOG_TAG, "error: " + e.getStackTrace().toString());
				}
			} else {
				if (this.exception != null) {
					Log.d(LOG_TAG, "exception in asynctask if any: " + this.exception.toString());
				}
			}
		}
	}
	
	
	private String generateRandomMid() {
		return "" + ( 100000000 + (int)(Math.random() * ((999999999 - 100000000) + 1)) );
	}
	
	
	private Bitmap fitInsideSquare(Bitmap b, int sideLength) {		
		int grabWidth = b.getWidth();
		int grabHeight = b.getHeight();
		
		float scaleX = ((float)sideLength) / grabWidth;
		float scaleY = ((float)sideLength) / grabHeight;
		float scale = Math.min(scaleX, scaleY);
		
		Matrix m = new Matrix();
		m.postScale(scale, scale);
		
		return Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight(), m, true);
	}
	
	
	private Bitmap makeInsideSquare(Bitmap b, int sideLength) {		
		int grabWidth = b.getWidth();
		int grabHeight = b.getHeight();
		if (grabWidth > grabHeight) {
			grabWidth = grabHeight;
		} else {
			grabHeight = grabWidth;
		}
		
		float scale = ((float)sideLength) / grabWidth;
		
		Matrix m = new Matrix();
		m.postScale(scale, scale);
		
		return Bitmap.createBitmap(b, 0, 0, grabWidth, grabHeight, m, true);
	}
	
	/**
	 * Called when the video view exits.
	 * 
	 * @param requestCode
	 *            The request code originally supplied to
	 *            startActivityForResult(), allowing you to identify who this
	 *            result came from.
	 * @param resultCode
	 *            The integer result code returned by the child activity through
	 *            its setResult().
	 * @param intent
	 *            An Intent, which can return result data to the caller (various
	 *            data can be attached to Intent "extras").
	 * @throws JSONException
	 */
	public void onActivityResult(int requestCode, int resultCode, Intent intent) {

		// Result received okay
		if (resultCode == Activity.RESULT_OK) {
			// An audio clip was requested
			if (requestCode == CAPTURE_AUDIO) {
				// Get the uri of the audio clip
				Uri data = intent.getData();
				// create a file object from the uri
				results.put(createMediaFile(data));

				if (results.length() >= limit) {
					// Send Uri back to JavaScript for listening to audio
					this.callbackContext.sendPluginResult(new PluginResult(
							PluginResult.Status.OK, results));
				} else {
					// still need to capture more audio clips
					captureAudio();
				}
			} else if (requestCode == CAPTURE_IMAGE) {
				// For some reason if I try to do:
				// Uri data = intent.getData();
				// It crashes in the emulator and on my phone with a null
				// pointer exception
				// To work around it I had to grab the code from
				// CameraLauncher.java
				try {
					// Create entry in media store for image
					// (Don't use insertImage() because it uses default
					// compression setting of 50 - no way to change it)
					ContentValues values = new ContentValues();
					values.put(
							android.provider.MediaStore.Images.Media.MIME_TYPE,
							IMAGE_JPEG);
					Uri uri = null;
					try {
						uri = this.cordova
								.getActivity()
								.getContentResolver()
								.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
										values);
					} catch (UnsupportedOperationException e) {
						LOG.d(LOG_TAG, "Can't write to external media storage.");
						try {
							uri = this.cordova
									.getActivity()
									.getContentResolver()
									.insert(android.provider.MediaStore.Images.Media.INTERNAL_CONTENT_URI,
											values);
						} catch (UnsupportedOperationException ex) {
							LOG.d(LOG_TAG,
									"Can't write to internal media storage.");
							this.fail(createErrorObject(CAPTURE_INTERNAL_ERR,
									"Error capturing image - no media storage found."));
							return;
						}
					}
					FileInputStream fis = new FileInputStream(
							this.getTempDirectoryPath(this.cordova
									.getActivity()) + "/Capture.jpg");
					OutputStream os = this.cordova.getActivity()
							.getContentResolver().openOutputStream(uri);
					byte[] buffer = new byte[4096];
					int len;
					while ((len = fis.read(buffer)) != -1) {
						os.write(buffer, 0, len);
					}
					os.flush();
					os.close();
					fis.close();
					
					
					String mid = generateRandomMid();
					
					FileInputStream fi = new FileInputStream(
							this.getTempDirectoryPath(this.cordova
									.getActivity()) + "/Capture.jpg");
					Bitmap bitmap = BitmapFactory.decodeStream(fi);
					fi.close();
					
					ExifInterface exif = new ExifInterface(this.getTempDirectoryPath(this.cordova.getActivity()) + "/Capture.jpg");
					
					int rotate = 0;
					
					if (exif.getAttribute(ExifInterface.TAG_ORIENTATION) != null) {
						int o = Integer.parseInt(exif.getAttribute(ExifInterface.TAG_ORIENTATION));

						Log.d(LOG_TAG, "z7");
						
				        if (o == ExifInterface.ORIENTATION_NORMAL) {
				        	rotate = 0;
				        } else if (o == ExifInterface.ORIENTATION_ROTATE_90) {
				        	rotate = 90;
				        } else if (o == ExifInterface.ORIENTATION_ROTATE_180) {
				        	rotate = 180;
				        } else if (o == ExifInterface.ORIENTATION_ROTATE_270) {
				        	rotate = 270;
				        } else {
				        	rotate = 0;
				        }
						
				        Log.d(LOG_TAG, "z8");
				        
				        Log.d(LOG_TAG, "rotate: " + rotate);
				        
						// try to correct orientation
						if (rotate != 0) {
							Matrix matrix = new Matrix();
							Log.d(LOG_TAG, "z9");
							matrix.setRotate(rotate);
							Log.d(LOG_TAG, "z10");
							bitmap = Bitmap.createBitmap(bitmap, 0, 0,
									bitmap.getWidth(), bitmap.getHeight(),
									matrix, true);
							Log.d(LOG_TAG, "z11");
						}
					}
					
					String filePath = this.getTempDirectoryPath(this.cordova.getActivity()) + "/econ_" + mid + ".jpg";
					FileOutputStream foEcon = new FileOutputStream(filePath);
					fitInsideSquare(bitmap, 850).compress(CompressFormat.JPEG, 45, foEcon);
			        foEcon.flush();
			        foEcon.close();
			        
			        String filePathMedium = this.getTempDirectoryPath(this.cordova.getActivity()) + "/medium_" + mid + ".jpg";
					FileOutputStream foMedium = new FileOutputStream(filePathMedium);
					makeInsideSquare(bitmap, 320).compress(CompressFormat.JPEG, 55, foMedium); 
			        foMedium.flush();
			        foMedium.close();
			        
			        String filePathThumb = this.getTempDirectoryPath(this.cordova.getActivity()) + "/thumb_" + mid + ".jpg";
					FileOutputStream foThumb = new FileOutputStream(filePathThumb);
					makeInsideSquare(bitmap, 175).compress(CompressFormat.JPEG, 55, foThumb); 
			        foThumb.flush();
			        foThumb.close();
			        
			        bitmap.recycle();
			        System.gc();

					// Add image to results
					JSONObject mediaFile = createMediaFile(uri);
					try {
						mediaFile.put("typeOfPluginResult", "initialRecordInformer");
						mediaFile.put("mid", mid);
						mediaFile.put("mediaType", "photo");
						mediaFile.put("filePath", filePath);
						mediaFile.put("filePathMedium", filePathMedium);
						mediaFile.put("filePathThumb", filePathThumb);
					} catch (JSONException e) {
						Log.d(LOG_TAG, "error: " + e.getStackTrace().toString());
					}
					
					// checkForDuplicateImage(); // i dont know what this does but i'm taken it out anyways!

					PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, (new JSONArray()).put(mediaFile));
					pluginResult.setKeepCallback(true);
					this.callbackContext.sendPluginResult(pluginResult);
					new UploadFilesToS3Task().execute(new File(filePath), new File(filePathMedium), new File(filePathThumb), this.callbackContext, mid, mediaFile);
				} catch (IOException e) {
					e.printStackTrace();
					this.fail(createErrorObject(CAPTURE_INTERNAL_ERR,
							"Error capturing image."));
				}
			} else if (requestCode == CAPTURE_VIDEO) {
				// Get the uri of the video clip
				
				Log.d(LOG_TAG, "activity result video");
				
				Uri uri = intent.getData();
				
				Log.d(LOG_TAG, "before create thumbnail");
				Bitmap bitmap = ThumbnailUtils.createVideoThumbnail((new File(this.getRealPathFromURI(uri, this.cordova))).getAbsolutePath(), MediaStore.Images.Thumbnails.MINI_KIND);
				Log.d(LOG_TAG, "after create thumbnail");
				String mid = generateRandomMid();
				
				try {
			        String filePathMedium = this.getTempDirectoryPath(this.cordova.getActivity()) + "/medium_" + mid + ".jpg";
					FileOutputStream foMedium = new FileOutputStream(filePathMedium);
					bitmap.compress(CompressFormat.JPEG, 100, foMedium); 
			        foMedium.flush();
			        foMedium.close();
			        
			        bitmap.recycle();
			        System.gc();
	
					// Add image to results
					JSONObject mediaFile = createMediaFile(uri);
					try {
						mediaFile.put("typeOfPluginResult", "initialRecordInformer");
						mediaFile.put("mid", mid);
						mediaFile.put("mediaType", "video");
						mediaFile.put("filePath", filePathMedium);
						mediaFile.put("filePathMedium", filePathMedium);
						mediaFile.put("filePathThumb", filePathMedium);
						String absolutePath = (new File(this.getRealPathFromURI(uri, this.cordova))).getAbsolutePath();
						mediaFile.put("fileExt", absolutePath.substring( absolutePath.lastIndexOf(".") + 1 ));
					} catch (JSONException e) {
						Log.d(LOG_TAG, "error: " + e.getStackTrace().toString());
					}
					Log.d(LOG_TAG, "mediafile at 638" + mediaFile.toString());
					PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, (new JSONArray()).put(mediaFile));
					pluginResult.setKeepCallback(true);
					this.callbackContext.sendPluginResult(pluginResult);
					new UploadVideoToS3Task().execute(new File(this.getRealPathFromURI(uri, this.cordova)), this.callbackContext, mid, mediaFile);
				} catch (FileNotFoundException e1) {
					e1.printStackTrace();
				} catch (IOException e1) {
					e1.printStackTrace();
				}
			}
		}
		// If canceled
		else if (resultCode == Activity.RESULT_CANCELED) {
			// If we have partial results send them back to the user
			if (results.length() > 0) {
				this.callbackContext.sendPluginResult(new PluginResult(
						PluginResult.Status.OK, results));
			}
			// user canceled the action
			else {
				this.fail(createErrorObject(CAPTURE_NO_MEDIA_FILES, "Canceled."));
			}
		}
		// If something else
		else {
			// If we have partial results send them back to the user
			if (results.length() > 0) {
				//this.callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, results));
			}
			// something bad happened
			else {
				this.fail(createErrorObject(CAPTURE_NO_MEDIA_FILES,
						"Did not complete!"));
			}
		}
	}

	/**
	 * Creates a JSONObject that represents a File from the Uri
	 * 
	 * @param data
	 *            the Uri of the audio/image/video
	 * @return a JSONObject that represents a File
	 * @throws IOException
	 */
	private JSONObject createMediaFile(Uri data) {
		File fp = new File(this.getRealPathFromURI(data, this.cordova));
		JSONObject obj = new JSONObject();

		try {
			// File properties
			obj.put("name", fp.getName());
			obj.put("fullPath", "file://" + fp.getAbsolutePath());
			// Because of an issue with MimeTypeMap.getMimeTypeFromExtension()
			// all .3gpp files
			// are reported as video/3gpp. I'm doing this hacky check of the URI
			// to see if it
			// is stored in the audio or video content store.
			if (fp.getAbsoluteFile().toString().endsWith(".3gp")
					|| fp.getAbsoluteFile().toString().endsWith(".3gpp")) {
				if (data.toString().contains("/audio/")) {
					obj.put("type", AUDIO_3GPP);
				} else {
					obj.put("type", VIDEO_3GPP);
				}
			} else {
				obj.put("type", FileUtils.getMimeType(fp.getAbsolutePath()));
			}

			obj.put("lastModifiedDate", fp.lastModified());
			obj.put("size", fp.length());
		} catch (JSONException e) {
			// this will never happen
			e.printStackTrace();
		}

		return obj;
	}

	private JSONObject createErrorObject(int code, String message) {
		JSONObject obj = new JSONObject();
		try {
			obj.put("code", code);
			obj.put("message", message);
		} catch (JSONException e) {
			// This will never happen
		}
		return obj;
	}
	
	private String getRealPathFromURI(Uri contentUri, CordovaInterface cordova) {
        final String scheme = contentUri.getScheme();
        
        if (scheme.compareTo("content") == 0) {
            String[] proj = { "_data" };
            Cursor cursor = cordova.getActivity().managedQuery(contentUri, proj, null, null, null);
            int column_index = cursor.getColumnIndexOrThrow("_data");
            cursor.moveToFirst();
            return cursor.getString(column_index);
        } else if (scheme.compareTo("file") == 0) {
            return contentUri.getPath();
        } else {
            return contentUri.toString();
        }
    }

	/**
	 * Send error message to JavaScript.
	 * 
	 * @param err
	 */
	public void fail(JSONObject err) {
		this.callbackContext.error(err);
	}

	/**
	 * Creates a cursor that can be used to determine how many images we have.
	 * 
	 * @return a cursor
	 */
	private Cursor queryImgDB(Uri contentStore) {
		return this.cordova
				.getActivity()
				.getContentResolver()
				.query(contentStore,
						new String[] { MediaStore.Images.Media._ID }, null,
						null, null);
	}

	/**
	 * Used to find out if we are in a situation where the Camera Intent adds to
	 * images to the content store.
	 */
	private void checkForDuplicateImage() {
		Uri contentStore = whichContentStore();
		Cursor cursor = queryImgDB(contentStore);
		int currentNumOfImages = cursor.getCount();

		// delete the duplicate file if the difference is 2
		if ((currentNumOfImages - numPics) == 2) {
			cursor.moveToLast();
			int id = Integer.valueOf(cursor.getString(cursor
					.getColumnIndex(MediaStore.Images.Media._ID))) - 1;
			Uri uri = Uri.parse(contentStore + "/" + id);
			this.cordova.getActivity().getContentResolver()
					.delete(uri, null, null);
		}
	}

	/**
	 * Determine if we are storing the images in internal or external storage
	 * 
	 * @return Uri
	 */
	private Uri whichContentStore() {
		if (Environment.getExternalStorageState().equals(
				Environment.MEDIA_MOUNTED)) {
			return android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
		} else {
			return android.provider.MediaStore.Images.Media.INTERNAL_CONTENT_URI;
		}
	}
}