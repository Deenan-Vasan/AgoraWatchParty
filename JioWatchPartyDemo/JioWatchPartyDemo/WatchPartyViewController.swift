//
//  WatchPartyViewController.swift
//  JioWatchPartyDemo
//
//  Created by Deenan on 30/08/22.
//

import UIKit
import AVKit
import AgoraRtcKit
import MediaPlayer

class WatchPartyViewController: UIViewController {
    
    @IBOutlet weak var vodContentView: UIView!
    @IBOutlet weak var videoCallView: UIView!
    @IBOutlet weak var videoCallUserOne: UIView!
    @IBOutlet weak var videoCallUserTwo: UIView!
    @IBOutlet weak var videoCallUserThree: UIView!
    @IBOutlet weak var videoCallUserFour: UIView!
    @IBOutlet weak var videoCallUserFive: UIView!
    @IBOutlet weak var videoCallUserSix: UIView!
    @IBOutlet weak var videoCallUserSeven: UIView!
    @IBOutlet weak var videoCallUserEight: UIView!
    @IBOutlet weak var videoCallUserOnePlaceholder: UIImageView!
    @IBOutlet weak var videoCallUserTwoPlaceholder: UIImageView!
    @IBOutlet weak var videoCallUserThreePlaceholder: UIImageView!
    @IBOutlet weak var videoCallUserFourPlaceholder: UIImageView!
    @IBOutlet weak var videoCallUserFivePlaceHolder: UIImageView!
    @IBOutlet weak var videoCallUserSixPlaceholder: UIImageView!
    @IBOutlet weak var videoCallUserSevenPlaceholder: UIImageView!
    @IBOutlet weak var videoCallUserEightPlaceholder: UIView!
    @IBOutlet weak var audioMuteButton: UIButton!
    @IBOutlet weak var videoMuteButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var runningTime: UILabel!
    @IBOutlet weak var totalDuration: UILabel!
    @IBOutlet weak var playbackSlider: UISlider!
    @IBOutlet weak var mpVolumeView: UIView!
    
    
    
    private var vPlayer: AVPlayer!
    var agoraKit: AgoraRtcEngineKit!
    var localVideo: AgoraRtcVideoCanvas?
    var remoteVideo: AgoraRtcVideoCanvas?
    let AppID: String = "84d1d68094e140a28866692db46b51fe"
    var userJoined: Int = 0
    var remoteUserIDs: [Int] = []
    var channelName = ""
    var totalRemoteUsers = [2,3,4,5,6,7,8]
    var isPlaying: Bool = false
    fileprivate let seekDuration: Float64 = 10
    
    private var isSwitchCamera = false {
        didSet {
            agoraKit.switchCamera()
        }
    }
    
    private var isMutedVideo = false {
        didSet {
            // mute local video
            agoraKit.muteLocalVideoStream(isMutedVideo)
            videoMuteButton.isSelected = isMutedVideo
            videoCallUserOnePlaceholder.isHidden = !(isMutedVideo)
        }
    }
    
    private var isMutedAudio = false {
        didSet {
            // mute local audio
            agoraKit.muteLocalAudioStream(isMutedAudio)
            audioMuteButton.isSelected = isMutedAudio
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.loadVideo()
        agoraInitializeVideoCall()
        setAVSession()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInteruption), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
    }
    
    func agoraInitializeVideoCall() {
        initializeAgoraEngine()
        setupVideo()
        isMutedVideo = false
        setupLocalVideo()
        joinChannel()
    }
    
    @objc private func handleInteruption() {
        print("handleInteruption")
        self.vPlayer.play()
    }
    
    func setAVSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .moviePlayback, options: .defaultToSpeaker)
        } catch {
            print(error)
        }
    }
    
    private func loadVideo() {
        //  http://content.jwplatform.com/manifests/vM7nH0Kl.m3u8
        // http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8
        // https://bitmovin-a.akamaihd.net/content/MI201109210084_1/mpds/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.mpd
        // https://sample-videos.com/video123/mp4/480/big_buck_bunny_480p_20mb.mp4
        let urlStr = "http://content.jwplatform.com/manifests/vM7nH0Kl.m3u8"
        
        if let videoUrl = URL(string: urlStr) {
            print("video url is correct.")
            let playerItem: AVPlayerItem = AVPlayerItem(url: videoUrl)
            vPlayer = AVPlayer(playerItem: playerItem)

            let videoLayer = AVPlayerLayer(player: vPlayer)
            videoLayer.videoGravity = .resizeAspect
            videoLayer.frame = self.vodContentView.bounds
            self.vodContentView.layer.addSublayer(videoLayer)
            isPlaying = true
            vPlayer.volume = 1.0
            vPlayer.play()
            playButton.setImage(UIImage(named: "avplayer_pause"), for: .normal)
            //vPlayer.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(videoDidStalled), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: vPlayer?.currentItem)
            NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnded), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: vPlayer?.currentItem)
            
            // Add playback slider
            playbackSlider.minimumValue = 0
            
            playbackSlider.addTarget(self, action: #selector(WatchPartyViewController.playbackSliderValueChanged(_:)), for: .valueChanged)
            
            let duration : CMTime = playerItem.asset.duration
            let seconds : Float64 = CMTimeGetSeconds(duration)
            totalDuration.text = self.stringFromTimeInterval(interval: seconds)
            
            let duration1 : CMTime = playerItem.currentTime()
            let seconds1 : Float64 = CMTimeGetSeconds(duration1)
            runningTime.text = self.stringFromTimeInterval(interval: seconds1)
            
            playbackSlider.maximumValue = Float(seconds)
            playbackSlider.isContinuous = true
            playbackSlider.tintColor = UIColor(red: 0.93, green: 0.74, blue: 0.00, alpha: 1.00)
            
            vPlayer!.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { (CMTime) -> Void in
                if self.vPlayer!.currentItem?.status == .readyToPlay {
                    let time : Float64 = CMTimeGetSeconds(self.vPlayer!.currentTime());
                    self.playbackSlider.value = Float ( time );
                    
                    self.runningTime.text = self.stringFromTimeInterval(interval: time)
                }
            }
        }
//        let volumeView = MPVolumeView(frame: mpVolumeView.bounds)
//        mpVolumeView.addSubview(volumeView)
    }
    
    @objc func playbackSliderValueChanged(_ playbackSlider:UISlider) {
        let seconds : Int64 = Int64(playbackSlider.value)
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        
        vPlayer!.seek(to: targetTime)
        
        if vPlayer!.rate == 0 {
            vPlayer?.play()
        }
    }
    
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func doMuteAudioPressed(_ sender: UIButton) {
        isMutedAudio.toggle()
    }
    
    @IBAction func doMuteVideoPressed(_ sender: UIButton) {
        isMutedVideo.toggle()
    }
    
    @IBAction func doSwitchCameraPressed(_ sender: UIButton) {
        isSwitchCamera.toggle()
    }
    
    @IBAction func doLeavePressed(_ sender: UIButton) {
        leaveChannel()
    }
    
    @IBAction private func onPlayButtonClicked(_ sender: UIButton) {
        if vPlayer.timeControlStatus == .paused {
            self.vPlayer.play()
            playButton.setImage(UIImage(named: "avplayer_pause"), for: .normal)
        } else if vPlayer.timeControlStatus == .playing {
            self.vPlayer.pause()
            playButton.setImage(UIImage(named: "avplayer_play"), for: .normal)
        }
        if !(isPlaying) {
            loadVideo()
        }
    }
    
    @IBAction func onFastBackwardClicked(_ sender: UIButton) {
        if vPlayer == nil { return }
        let playerCurrenTime = CMTimeGetSeconds(vPlayer!.currentTime())
        var newTime = playerCurrenTime - seekDuration
        if newTime < 0 { newTime = 0 }
        vPlayer?.pause()
        let selectedTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        vPlayer?.seek(to: selectedTime)
        vPlayer?.play()
        playButton.setImage(UIImage(named: "avplayer_play"), for: .normal)
    }
    
    @IBAction func onFastForwardClicked(_ sender: UIButton) {
        if vPlayer == nil { return }
        if let duration  = vPlayer!.currentItem?.duration {
            let playerCurrentTime = CMTimeGetSeconds(vPlayer!.currentTime())
            let newTime = playerCurrentTime + seekDuration
            if newTime < CMTimeGetSeconds(duration)
            {
                let selectedTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
                vPlayer!.seek(to: selectedTime)
            }
            vPlayer?.pause()
            vPlayer?.play()
            playButton.setImage(UIImage(named: "avplayer_play"), for: .normal)
        }
    }
    
}

// Agora RTC APIs
extension WatchPartyViewController {
    
    func initializeAgoraEngine() {
        // init AgoraRtcEngineKit
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: AppID, delegate: self)
    }
    
    func setupVideo() {
        // In simple use cases, we only need to enable video capturing
        // and rendering once at the initialization step.
        // Note: audio recording and playing is enabled by default.
        agoraKit.enableVideo()
        
        // Set video configuration
        // Please go to this page for detailed explanation
        // https://docs.agora.io/cn/Voice/API%20Reference/java/classio_1_1agora_1_1rtc_1_1_rtc_engine.html#af5f4de754e2c1f493096641c5c5c1d8f
        agoraKit.setVideoEncoderConfiguration(AgoraVideoEncoderConfiguration(size: AgoraVideoDimension240x240,
                                                                             frameRate: .fps15,
                                                                             bitrate: AgoraVideoBitrateStandard,
                                                                             orientationMode: .adaptative))
    }
    
    func setupLocalVideo() {
        // This is used to set a local preview.
        // The steps setting local and remote view are very similar.
        // But note that if the local user do not have a uid or do
        // not care what the uid is, he can set his uid as ZERO.
        // Our server will assign one and return the uid via the block
        // callback (joinSuccessBlock) after
        // joining the channel successfully.
        //let view = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: videoCallUserOne.frame.size))
        localVideo = AgoraRtcVideoCanvas()
        localVideo!.view = videoCallUserOne
        localVideo!.renderMode = .hidden
        agoraKit.setupLocalVideo(localVideo)
        agoraKit.startPreview()
    }
    
    func joinChannel() {
        // Set audio route to speaker
        agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        
        // 1. Users can only see each other after they join the
        // same channel successfully using the same app id.
        // 2. One token is only valid for the channel name that
        // you use to generate this token.
        agoraKit.joinChannel(byToken: "", channelId: channelName, info: nil, uid: 0) { [unowned self] (channel, uid, elapsed) -> Void in
            // Did join channel "demoChannel1"
            print("join channel success.")
        }
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func leaveChannel() {
        // Step 1, release local AgoraRtcVideoCanvas instance
        agoraKit.setupLocalVideo(nil)
        // Step 2, leave channel and end group chat
        agoraKit.leaveChannel(nil)
        setIdleTimerActive(true)
        self.dismiss(animated: false)
    }
    
    func setIdleTimerActive(_ active: Bool) {
        UIApplication.shared.isIdleTimerDisabled = !active
    }
}

// Agora RTC Delegates
extension WatchPartyViewController: AgoraRtcEngineDelegate {
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        if remoteUserIDs.count < 8 {
            remoteUserIDs.append(Int(uid))
            reloadData()
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        if let index = remoteUserIDs.firstIndex(where: { $0 == uid }) {
            remoteUserIDs.remove(at: index)
            reloadData()
        }
    }
    
    func reloadData() {
        for i in (0 ..< remoteUserIDs.count) {
            let remoteID = remoteUserIDs[i]
            let videoCanvas = AgoraRtcVideoCanvas()
            videoCanvas.uid = UInt(remoteID)
            videoCanvas.view = userView(i+1)
            videoCanvas.renderMode = .hidden
            agoraKit.setupRemoteVideo(videoCanvas)
        }
        updatePlaceholderView()
    }
    
    func updatePlaceholderView() {
        let leftUsers = totalRemoteUsers.suffix(from: remoteUserIDs.count)
        print("leftUsers\(leftUsers)")
        for i in leftUsers {
            print("i -> \(i )")
            placeholderView(i)
        }
    }
    
    func userView(_ userCount: Int) -> UIView? {
        switch userCount {
        case 0:
            return videoCallUserOne
        case 1:
            videoCallUserTwoPlaceholder.isHidden = true
            videoCallUserTwo.isHidden = false
            return videoCallUserTwo
        case 2:
            videoCallUserThreePlaceholder.isHidden = true
            videoCallUserThree.isHidden = false
            return videoCallUserThree
        case 3:
            videoCallUserFourPlaceholder.isHidden = true
            videoCallUserFour.isHidden = false
            return videoCallUserFour
        case 4:
            videoCallUserFivePlaceHolder.isHidden = true
            videoCallUserFive.isHidden = false
            return videoCallUserFive
        case 5:
            videoCallUserSixPlaceholder.isHidden = true
            videoCallUserSix.isHidden = false
            return videoCallUserSix
        case 6:
            videoCallUserSevenPlaceholder.isHidden = true
            videoCallUserSeven.isHidden = false
            return videoCallUserSeven
        case 7:
            videoCallUserEightPlaceholder.isHidden = true
            videoCallUserEight.isHidden = false
            return videoCallUserEight
        default:
            return UIView()
        }
    }
    
    func placeholderView(_ userCount: Int) {
        switch userCount {
        case 2:
            videoCallUserTwoPlaceholder.isHidden = false
            videoCallUserTwo.isHidden = true
        case 3:
            videoCallUserThreePlaceholder.isHidden = false
            videoCallUserThree.isHidden = true
        case 4:
            videoCallUserFourPlaceholder.isHidden = false
            videoCallUserFour.isHidden = true
        case 5:
            videoCallUserFivePlaceHolder.isHidden = false
            videoCallUserFive.isHidden = true
        case 6:
            videoCallUserSixPlaceholder.isHidden = false
            videoCallUserSix.isHidden = true
        case 7:
            videoCallUserSevenPlaceholder.isHidden = false
            videoCallUserSeven.isHidden = true
        case 8:
            videoCallUserEightPlaceholder.isHidden = false
            videoCallUserEight.isHidden = true
        default:
            print("placeholderView")
        }
    }
    
}

// IB Actions
extension WatchPartyViewController {
    override class func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

    }
    
    
    @objc private func videoDidEnded() {
        playButton.setImage(UIImage(named: "avplayer_play"), for: .normal)
        isPlaying = false
        // removing the Observer
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func videoDidStalled() {
        print("videoDidStalled")
        NotificationCenter.default.removeObserver(self)
    }
    
    
}
