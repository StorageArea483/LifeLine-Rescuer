import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class CallService {
  static final JitsiMeet _jitsiMeet = JitsiMeet();

  static String generateCallId(String userId, String otherUserId) {
    final ids = [userId, otherUserId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  static Future<String> initiateCall({
    required String callerId,
    required String receiverId,
    required String callerName,
    required String callerPhotoUrl,
    bool audioOnly = false,
  }) async {
    final callId = generateCallId(callerId, receiverId);

    await FirebaseFirestore.instance.collection('calls').doc(callId).set({
      'callId': callId,
      'senderId': callerId,
      'receiverId': receiverId,
      'callerName': callerName,
      'callerPhotoUrl': callerPhotoUrl,
      'status': 'ringing',
      'audioOnly': audioOnly,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return callId;
  }

  static Future<void> acceptCall({
    required String callId,
    required String displayName,
    required String avatarUrl,
    required bool audioOnly,
  }) async {
    final doc =
        await FirebaseFirestore.instance.collection('calls').doc(callId).get();
    if (!doc.exists || doc.data()?['status'] != 'ringing') {
      return;
    }
    await FirebaseFirestore.instance.collection('calls').doc(callId).update({
      'status': 'accepted',
    });

    await joinRoom(
      roomName: callId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      audioOnly: audioOnly,
    );
  }

  static Future<void> declineCall(String callId) async {
    await FirebaseFirestore.instance.collection('calls').doc(callId).update({
      'status': 'declined',
    });
  }

  static Future<void> cancelCall(String callId) async {
    await FirebaseFirestore.instance.collection('calls').doc(callId).delete();
    await hangUp();
  }

  static Future<void> endCall(String callId) async {
    await FirebaseFirestore.instance.collection('calls').doc(callId).update({
      'status': 'ended',
    });
  }

  static Future<void> joinRoom({
    required String roomName,
    required String displayName,
    required String avatarUrl,
    required bool audioOnly,
  }) async {
    final options = JitsiMeetConferenceOptions(
      serverURL: 'https://meet.jit.si',
      room: roomName,
      configOverrides: {
        'disableDeepLinking': true,
        "prejoinPageEnabled": false,
        'startWithAudioMuted': false,
        'startWithVideoMuted': audioOnly,
        'subject': 'LifeLine Call',
        'enableLobbyChat': false,
        'enableInsecureRoomNameWarning': false,
        'enableInviteFunctions': false,
        'hideConferenceTimer': false,
        'toolbarButtons': ['microphone', 'camera', 'hangup'],
      },
      featureFlags: {
        FeatureFlags.welcomePageEnabled: false,
        FeatureFlags.preJoinPageEnabled: false,
        FeatureFlags.unsafeRoomWarningEnabled: false,
        FeatureFlags.addPeopleEnabled: false,
        FeatureFlags.inviteEnabled: false,
        FeatureFlags.resolution: FeatureFlagVideoResolutions.resolution720p,
        FeatureFlags.audioOnlyButtonEnabled: true,
        FeatureFlags.lobbyModeEnabled: false,
        FeatureFlags.chatEnabled: false,
        FeatureFlags.raiseHandEnabled: false,
        FeatureFlags.conferenceTimerEnabled: true,
      },
      userInfo: JitsiMeetUserInfo(displayName: displayName, avatar: avatarUrl),
    );

    final listener = JitsiMeetEventListener(
      conferenceTerminated: (url, error) async {
        try {
          await endCall(roomName);
        } catch (_) {
          // ignore errors
        }
      },
    );

    await _jitsiMeet.join(options, listener);
  }

  static Future<void> hangUp() async {
    await _jitsiMeet.hangUp();
  }
}
