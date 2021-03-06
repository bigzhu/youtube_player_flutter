part of 'youtube_player.dart';

class _Player extends StatefulWidget {
  final YoutubePlayerController controller;
  final YoutubePlayerFlags flags;

  _Player({
    this.controller,
    this.flags,
  });

  @override
  __PlayerState createState() => __PlayerState();
}

class __PlayerState extends State<_Player> with WidgetsBindingObserver {
  Completer<WebViewController> _webController = Completer<WebViewController>();

  // is paused by suspending
  bool isSuspendingPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // make sure js load cc module status correct
    if (widget.controller.isCCon)
      widget.controller.onCC();
    else
      widget.controller.offCC();

    switch (state) {
      case AppLifecycleState.resumed:
        if (isSuspendingPaused) {
          widget.controller?.play();
          isSuspendingPaused = false;
        } else
          widget.controller?.pause();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      //case AppLifecycleState.suspending:
      case AppLifecycleState.detached:
        if (widget.controller.value.isPlaying) {
          widget.controller?.pause();
          isSuspendingPaused = true;
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: WebView(
        initialUrl: player,
        javascriptMode: JavascriptMode.unrestricted,
        initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
        javascriptChannels: {
          JavascriptChannel(
            name: 'Ready',
            onMessageReceived: (JavascriptMessage message) {
              widget.controller.value = widget.controller.value.copyWith(isReady: true);
            },
          ),
          JavascriptChannel(
            name: 'StateChange',
            onMessageReceived: (JavascriptMessage message) {
              switch (message.message) {
                case '-1':
                  widget.controller.value =
                      widget.controller.value.copyWith(playerState: PlayerState.UN_STARTED, isLoaded: true);
                  break;
                case '0':
                  widget.controller.value = widget.controller.value.copyWith(playerState: PlayerState.ENDED);
                  break;
                case '1':
                  widget.controller.value = widget.controller.value.copyWith(
                    playerState: PlayerState.PLAYING,
                    isPlaying: true,
                    hasPlayed: true,
                    errorCode: 0,
                  );
                  break;
                case '2':
                  widget.controller.value = widget.controller.value.copyWith(
                    playerState: PlayerState.PAUSED,
                    isPlaying: false,
                  );
                  break;
                case '3':
                  widget.controller.value = widget.controller.value.copyWith(playerState: PlayerState.BUFFERING);
                  break;
                case '5':
                  widget.controller.value = widget.controller.value.copyWith(playerState: PlayerState.CUED);
                  break;
                default:
                  throw Exception("Invalid player state obtained.");
              }
            },
          ),
          JavascriptChannel(
            name: 'PlaybackQualityChange',
            onMessageReceived: (JavascriptMessage message) {
              //print("PlaybackQualityChange ${message.message}");
            },
          ),
          JavascriptChannel(
            name: 'PlaybackRateChange',
            onMessageReceived: (JavascriptMessage message) {
              switch (message.message) {
                case '2':
                  widget.controller.value = widget.controller.value.copyWith(playbackRate: PlaybackRate.DOUBLE);
                  break;
                case '1.5':
                  widget.controller.value = widget.controller.value.copyWith(playbackRate: PlaybackRate.ONE_AND_A_HALF);
                  break;
                case '1':
                  widget.controller.value = widget.controller.value.copyWith(playbackRate: PlaybackRate.NORMAL);
                  break;
                case '0.5':
                  widget.controller.value = widget.controller.value.copyWith(playbackRate: PlaybackRate.HALF);
                  break;
                case '0.25':
                  widget.controller.value = widget.controller.value.copyWith(playbackRate: PlaybackRate.QUARTER);
                  break;
                default:
                  widget.controller.value = widget.controller.value.copyWith(playbackRate: PlaybackRate.NORMAL);
              }
            },
          ),
          JavascriptChannel(
            name: 'Errors',
            onMessageReceived: (JavascriptMessage message) {
              widget.controller.value = widget.controller.value.copyWith(errorCode: int.tryParse(message.message) ?? 0);
            },
          ),
          JavascriptChannel(
            name: 'VideoData',
            onMessageReceived: (JavascriptMessage message) {
              var videoData = jsonDecode(message.message);
              double duration = videoData['duration'] * 1000;
              //print("VideoData ${message.message}");
              widget.controller.value = widget.controller.value.copyWith(
                duration: Duration(
                  milliseconds: duration.floor(),
                ),
              );
            },
          ),
          JavascriptChannel(
            name: 'CurrentTime',
            onMessageReceived: (JavascriptMessage message) {
              double position = (double.tryParse(message.message) ?? 0) * 1000;
              widget.controller.value = widget.controller.value.copyWith(
                position: Duration(
                  milliseconds: position.floor(),
                ),
              );
            },
          ),
          JavascriptChannel(
            name: 'LoadedFraction',
            onMessageReceived: (JavascriptMessage message) {
              widget.controller.value = widget.controller.value.copyWith(
                buffered: double.tryParse(message.message) ?? 0,
              );
            },
          ),
        },
        onWebViewCreated: (webController) {
          _webController.complete(webController);
          _webController.future.then(
            (controller) {
              widget.controller.value = widget.controller.value.copyWith(webViewController: webController);
            },
          );
        },
        onPageFinished: (_) {
          widget.controller.value = widget.controller.value.copyWith(
            isEvaluationReady: true,
          );
          if (widget.flags.forceHideAnnotation) {
            widget.controller.forceHideAnnotation();
          }
        },
      ),
    );
  }

  String get player {
    // String baseUrl = 'https://sarbagyadhaubanjar.github.io/youtube_player';
    String baseUrl = 'https://bigzhu.github.io/youtube_player/android';
    /*
    if (Platform.isAndroid) {
      baseUrl = '$baseUrl/android';
    } else if (Platform.isIOS) {
      baseUrl = '$baseUrl/ios';
    }
    */
    baseUrl = '$baseUrl?cc_load_policy=1&v=3';
    return baseUrl;
  }
}
