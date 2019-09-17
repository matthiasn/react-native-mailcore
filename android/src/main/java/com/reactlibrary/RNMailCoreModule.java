
package com.reactlibrary;

import android.net.Uri;

import com.facebook.react.bridge.*;

import com.libmailcore.*;

import java.util.ArrayList;
import java.util.List;

public class RNMailCoreModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  public RNMailCoreModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @Override
  public String getName() {
    return "RNMailCore";
  }

  @ReactMethod
  public void sendMail(final ReadableMap obj, final Promise promise){
    getCurrentActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
        SMTPSession smtpSession = new SMTPSession();
        smtpSession.setHostname(obj.getString("hostname"));
        smtpSession.setPort(obj.getInt("port"));
        smtpSession.setUsername(obj.getString("username"));
        smtpSession.setPassword(obj.getString("password"));
        smtpSession.setAuthType(AuthType.AuthTypeSASLPlain);
        smtpSession.setConnectionType(ConnectionType.ConnectionTypeTLS);

        ReadableMap fromObj = obj.getMap("from");
        Address fromAddress = new Address();
        fromAddress.setDisplayName(fromObj.getString("addressWithDisplayName"));
        fromAddress.setMailbox(fromObj.getString("mailbox"));

        ReadableMap toObj = obj.getMap("to");
        Address toAddress = new Address();
        toAddress.setDisplayName(toObj.getString("addressWithDisplayName"));
        toAddress.setMailbox(toObj.getString("mailbox"));

        ArrayList<Address> toAddressList = new ArrayList();
        toAddressList.add(toAddress);

        MessageHeader messageHeader = new MessageHeader();
        messageHeader.setSubject(obj.getString("subject"));
        messageHeader.setTo(toAddressList);
        messageHeader.setFrom(fromAddress);

        MessageBuilder messageBuilder = new MessageBuilder();
        messageBuilder.setHeader(messageHeader);
        messageBuilder.setHTMLBody(obj.getString("htmlBody"));

        SMTPOperation smtpOperation = smtpSession.sendMessageOperation(fromAddress, toAddressList, messageBuilder.data());
        smtpOperation.start(new OperationCallback() {
          @Override
          public void succeeded() {
            WritableMap result = Arguments.createMap();
            result.putString("status", "SUCCESS");
            promise.resolve(result);
          }

          @Override
          public void failed(MailException e) {
            promise.reject(String.valueOf(e.errorCode()), e.getMessage());
          }
        });
      }
    });

  }

  @ReactMethod
  public void saveImap(final ReadableMap obj, final Promise promise){
    getCurrentActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {

        IMAPSession imapSession = new IMAPSession();
        imapSession.setHostname(obj.getString("hostname"));
        imapSession.setPort(obj.getInt("port"));
        imapSession.setUsername(obj.getString("username"));
        imapSession.setPassword(obj.getString("password"));
        imapSession.setAuthType(AuthType.AuthTypeSASLPlain);
        imapSession.setConnectionType(ConnectionType.ConnectionTypeTLS);

        ReadableMap fromObj = obj.getMap("from");
        Address fromAddress = new Address();
        fromAddress.setDisplayName(fromObj.getString("addressWithDisplayName"));
        fromAddress.setMailbox(fromObj.getString("mailbox"));

        ReadableMap toObj = obj.getMap("to");
        Address toAddress = new Address();
        toAddress.setDisplayName(toObj.getString("addressWithDisplayName"));
        toAddress.setMailbox(toObj.getString("mailbox"));

        ArrayList<Address> toAddressList = new ArrayList();
        toAddressList.add(toAddress);

        String folder = obj.getString("folder");

        MessageHeader messageHeader = new MessageHeader();
        messageHeader.setSubject(obj.getString("subject"));
        messageHeader.setTo(toAddressList);
        messageHeader.setFrom(fromAddress);

        MessageBuilder messageBuilder = new MessageBuilder();
        messageBuilder.setHeader(messageHeader);
        messageBuilder.setHTMLBody(obj.getString("textBody"));

        if (obj.hasKey("attachmentUri")) {
          try {
            String uri = obj.getString("attachmentUri");
            String path = Uri.parse(uri).getPath();
            Attachment att = Attachment.attachmentWithContentsOfFile(path);
            att.setFilename(obj.getString("filename"));
            messageBuilder.addAttachment(att);
          } catch (Exception e) {
          }
        }

        if (obj.hasKey("audiofile")) {
          try {
            String filename = obj.getString("audiofile");
            String path = obj.getString("audiopath");
            Attachment att = Attachment.attachmentWithContentsOfFile(path);
            att.setFilename(filename);
            att.setMimeType("audio/m4a");
            messageBuilder.addAttachment(att);
          } catch (Exception e) {
          }
        }

        IMAPOperation imapOperation = imapSession.appendMessageOperation(folder, messageBuilder.data(), 0);
        imapOperation.start(new OperationCallback() {
          @Override
          public void succeeded() {
            WritableMap result = Arguments.createMap();
            result.putString("status", "SUCCESS");
            promise.resolve(result);
          }

          @Override
          public void failed(MailException e) {
            promise.reject(String.valueOf(e.errorCode()), e.getMessage());
          }
        });
      }
    });
  }

  @ReactMethod
  public void fetchImap(final ReadableMap obj, final Promise promise){
    getCurrentActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {

        IMAPSession imapSession = new IMAPSession();
        imapSession.setHostname(obj.getString("hostname"));
        imapSession.setPort(obj.getInt("port"));
        imapSession.setUsername(obj.getString("username"));
        imapSession.setPassword(obj.getString("password"));
        imapSession.setAuthType(AuthType.AuthTypeSASLPlain);
        imapSession.setConnectionType(ConnectionType.ConnectionTypeTLS);

        String folder = obj.getString("folder");

        int minUid = obj.getInt("minUid");
        int length = obj.getInt("length");
        IndexSet uidSet = IndexSet.indexSetWithRange(new Range(minUid, minUid + length));
        final IMAPFetchMessagesOperation fetchOp = imapSession.fetchMessagesByUIDOperation(folder, 0, uidSet);

        fetchOp.start(new OperationCallback() {
          @Override
          public void succeeded() {
            ArrayList<String> uids = new ArrayList<>();

            for (IMAPMessage msg : fetchOp.messages()) {
              uids.add(Long.toString(msg.uid()));
            }

            String result = String.join(" ", uids);

            promise.resolve(result);
          }

          @Override
          public void failed(MailException e) {
            promise.reject(String.valueOf(e.errorCode()), e.getMessage());
          }
        });
      }
    });
  }

  @ReactMethod
  public void fetchImapByUid(final ReadableMap obj, final Promise promise){
    getCurrentActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {

        IMAPSession imapSession = new IMAPSession();
        imapSession.setHostname(obj.getString("hostname"));
        imapSession.setPort(obj.getInt("port"));
        imapSession.setUsername(obj.getString("username"));
        imapSession.setPassword(obj.getString("password"));
        imapSession.setAuthType(AuthType.AuthTypeSASLPlain);
        imapSession.setConnectionType(ConnectionType.ConnectionTypeTLS);

        String folder = obj.getString("folder");
        int uid = obj.getInt("uid");

        final IMAPFetchParsedContentOperation fetchOp = imapSession.fetchParsedMessageByUIDOperation(folder, uid);

        fetchOp.start(new OperationCallback() {
          @Override
          public void succeeded() {
            String body = fetchOp.parser().plainTextBodyRendering(true);
            WritableMap result = Arguments.createMap();
            result.putString("status", "SUCCESS");
            result.putString("body", body);
            promise.resolve(result);
          }

          @Override
          public void failed(MailException e) {
            promise.reject(String.valueOf(e.errorCode()), e.getMessage());
          }
        });
      }
    });
  }

}
