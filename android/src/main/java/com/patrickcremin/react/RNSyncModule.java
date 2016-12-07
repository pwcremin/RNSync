package com.patrickcremin.react;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableNativeMap;

import com.cloudant.sync.query.IndexManager;
import com.cloudant.sync.query.QueryResult;
import com.cloudant.sync.datastore.Datastore;
import com.cloudant.sync.datastore.DatastoreManager;
import com.cloudant.sync.datastore.DocumentBodyFactory;

import com.cloudant.sync.datastore.DocumentRevision;
import com.cloudant.sync.datastore.UnsavedFileAttachment;
import com.cloudant.sync.event.Subscribe;
import com.cloudant.sync.notifications.ReplicationCompleted;
import com.cloudant.sync.notifications.ReplicationErrored;
import com.cloudant.sync.replication.ErrorInfo;
import com.cloudant.sync.replication.Replicator;
import com.cloudant.sync.replication.ReplicatorBuilder;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;

import com.google.gson.Gson;

import android.content.Context;

import java.io.File;

import java.net.URI;
import java.util.HashMap;
import java.util.Map;
import java.util.Iterator;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;

class Listener {

    private final CountDownLatch latch;
    public ErrorInfo error = null;
    public int documentsReplicated;
    public int batchesReplicated;

    Listener(CountDownLatch latch) {
        this.latch = latch;
    }

    @Subscribe
    public void complete(ReplicationCompleted event) {
        this.documentsReplicated = event.documentsReplicated;
        this.batchesReplicated = event.batchesReplicated;
        latch.countDown();
    }

    @Subscribe
    public void error(ReplicationErrored event) {
        this.error = event.errorInfo;
        latch.countDown();
    }
}

public class RNSyncModule extends ReactContextBaseJavaModule {

    private DatastoreManager manager;
    private Replicator replicator;
    private URI uri;
    private Datastore ds;
    private IndexManager im;

    public RNSyncModule(ReactApplicationContext reactContext) {
        super(reactContext);

        File path = reactContext.getApplicationContext().getDir("datastores", Context.MODE_PRIVATE);
        manager = new DatastoreManager(path.getAbsolutePath());
    }

    @Override
    public String getName() {
        return "RNSync";
    }

    // TODO let them name the datastore
    @ReactMethod
    public void init(String databaseUrl, Callback callback) {

        try {
            uri = new URI(databaseUrl);
            ds = manager.openDatastore("my_datastore");
            im = new IndexManager(ds);
        }
        catch (Exception e)
        {
            callback.invoke(e.getMessage());
            return;
        }

        callback.invoke();
    }

    // TODO need push and pull replication functions
    @ReactMethod
    public void replicatePush(Callback callback) {

        // Replicate from the local to remote database
        Replicator replicator = ReplicatorBuilder.push().from(ds).to(uri).build();

        CountDownLatch latch = new CountDownLatch(1);

        Listener listener = new Listener(latch);

        replicator.getEventBus().register(listener);

        // Fire-and-forget (there are easy ways to monitor the state too)
        replicator.start();

        try {
            latch.await();

            if (replicator.getState() != Replicator.State.COMPLETE) {
                callback.invoke(listener.error.getException().getMessage());
            } else {
                callback.invoke(null, String.format("Replicated %d documents in %d batches",
                        listener.documentsReplicated, listener.batchesReplicated));
            }
        }
        catch (Exception e)
        {
            callback.invoke(e.getMessage());
        }
        finally {
            replicator.getEventBus().unregister(listener);
        }
    }

    @ReactMethod
    public void replicatePull(Callback callback) {

        // Replicate from the local to remote database
        Replicator replicator = ReplicatorBuilder.pull().from(uri).to(ds).build();

        CountDownLatch latch = new CountDownLatch(1);

        Listener listener = new Listener(latch);

        replicator.getEventBus().register(listener);

        replicator.start();

        try {
            latch.await();
            replicator.getEventBus().unregister(listener);

            if (replicator.getState() != Replicator.State.COMPLETE) {
                callback.invoke(listener.error.getException().getMessage());
            } else {
                callback.invoke(null, String.format("Replicated %d documents in %d batches",
                        listener.documentsReplicated, listener.batchesReplicated));
            }

        }
        catch (Exception e)
        {
            callback.invoke(e.getMessage());
        }
        finally {
            replicator.getEventBus().unregister(listener);
        }
    }

    @ReactMethod
    public void create(ReadableMap body, String id, Callback callback) {

        ReadableNativeMap nativeBody = (ReadableNativeMap) body;

        DocumentRevision revision;

        if (id != null && !id.isEmpty()) {
            revision = new DocumentRevision(id);
        }
        else {
            revision = new DocumentRevision();
        }

        if(body == null) {
            revision.setBody(DocumentBodyFactory.create(new HashMap<String, Object>()));
        }
        else{
            revision.setBody(DocumentBodyFactory.create(nativeBody.toHashMap()));
        }

        try {
            DocumentRevision saved = ds.createDocumentFromRevision(revision);

            WritableMap doc = this.createWriteableMapFromHashMap(this.createDoc(saved));

            callback.invoke(null, doc);
        }
        catch (Exception e)
        {
            callback.invoke(e.getMessage());
            return;
        }
    }

    // TODO need ability to update and remove attachments
    @ReactMethod
    public void addAttachment(String id, String name, String path, String type, Callback callback) {

        try{
            DocumentRevision revision = ds.getDocument(id);

            // Add an attachment -- binary data like a JPEG
            UnsavedFileAttachment att1 =
                    new UnsavedFileAttachment(new File(path), type);

            revision.getAttachments().put(att1.name, att1);
            DocumentRevision updated = ds.updateDocumentFromRevision(revision);

            WritableMap doc = this.createWriteableMapFromHashMap(this.createDoc(updated));

            callback.invoke(null, doc );
        }
        catch (Exception e) {
            callback.invoke(e.getMessage());
            return;
        }
    }

    @ReactMethod
    public void retrieve(String id, Callback callback) {
        try{
            DocumentRevision revision = ds.getDocument(id);

            WritableMap doc = this.createWriteableMapFromHashMap(this.createDoc(revision));

            callback.invoke(null, doc);
        }
        catch (Exception e) {
            callback.invoke(e.getMessage());
            return;
        }
    }

    @ReactMethod
    public void update(String id, String rev, ReadableMap body, Callback callback) {

        try {
            DocumentRevision revision = ds.getDocument(id);

            ReadableNativeMap nativeBody = (ReadableNativeMap) body;

            revision.setBody(DocumentBodyFactory.create(nativeBody.toHashMap()));

            DocumentRevision updated = ds.updateDocumentFromRevision(revision);

            WritableMap doc = this.createWriteableMapFromHashMap(this.createDoc(updated));

            callback.invoke(null, doc);
        }
        catch (Exception e)
        {
            callback.invoke(e.getMessage());
        }
    }

    @ReactMethod
    public void delete(String id, Callback callback) {

        try {
            DocumentRevision revision = ds.getDocument(id);

            ds.deleteDocumentFromRevision(revision);

            callback.invoke();
        }
        catch (Exception e)
        {
            callback.invoke(e.getMessage());
            return;
        }
    }

    @ReactMethod
    public void find(ReadableMap query, ReadableArray fields, Callback callback) {

        ReadableNativeMap nativeQuery = (ReadableNativeMap) query;

        QueryResult result;

        if(fields == null)
        {
            result = im.find(nativeQuery.toHashMap(), 0, 0, null, null);
        }
        else
        {
            List<String> fieldslist = new ArrayList<>();
            for (int i = 0; i < fields.size(); i++) {
                fieldslist.add(fields.getString(i));
            }

            result = im.find(nativeQuery.toHashMap(), 0, 0, fieldslist, null);
        }


        WritableArray docs = new WritableNativeArray();

        for (DocumentRevision revision : result) {

            String jsonString = new Gson().toJson(this.createDoc(revision));

            docs.pushString(jsonString);
        }

        callback.invoke(null, docs);
    }

    private HashMap<String, Object> createDoc(DocumentRevision revision)
    {
        HashMap<String, Object> doc = new HashMap<>();
        doc.put("id", revision.getId());
        doc.put("rev", revision.getRevision());
        doc.put("body", revision.getBody().asMap());


        // TODO map attachments
//        WritableArray attachments = new WritableNativeArray();
//        Iterator it = revision.getAttachments().entrySet().iterator();
//        while (it.hasNext()) {
//            Map.Entry pair = (Map.Entry)it.next();
//            System.out.println(pair.getKey() + " = " + pair.getValue());
//            String key = (String)pair.getKey();
//            //attachments.put((String)pair.getKey(), pair.getValue());
//            attachments.pushString(pair.getValue().toString());
//            it.remove(); // avoids a ConcurrentModificationException
//        }
//        doc.put("attachments", attachments);

        return doc;
    }

    private WritableMap createWriteableMapFromHashMap(HashMap<String, Object> doc) {

        WritableMap data = Arguments.createMap();

        for (Map.Entry<String, Object> entry : doc.entrySet()) {
            String key = entry.getKey();
            Object value = entry.getValue();

            String typeName = value.getClass().getName();

            switch (typeName) {
                case "java.lang.Boolean":
                    data.putBoolean(key, (Boolean) value);
                    break;
                case "java.lang.Integer":
                    data.putInt(key, (Integer) value);
                    break;
                case "java.lang.Double":
                    data.putDouble(key, (Double) value);
                    break;
                case "java.lang.String":
                    data.putString(key, (String) value);
                    break;
                case "com.facebook.react.bridge.WritableNativeMap":
                    data.putMap(key, (WritableMap) value);
                    break;
                case "java.util.HashMap":
                    data.putMap(key, this.createWriteableMapFromHashMap((HashMap<String, Object>)value));
                    break;
                case "com.facebook.react.bridge.WritableNativeArray":
                    data.putArray(key, (WritableArray)value);
            }
        }

        return data;
    }
}
