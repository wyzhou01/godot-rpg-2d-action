extends Node
## 简易 BGM 播放器（用 AudioStreamGenerator 运行时合成正弦波）
## 不需要外部音频文件，可直接测试
##
## 简化版：只生成单音正弦波（4 拍循环）
## 真实部署时建议替换为 .ogg/.mp3 文件

@export var bpm: float = 100.0
@export var volume_db: float = -18.0

var _stream: AudioStreamGenerator = null
var _player: AudioStreamPlayer = null
var _playback: AudioStreamGeneratorPlayback = null
var _phase: float = 0.0
var _is_playing: bool = false
var _chapter: int = 1

# 简单 4 拍旋律 (各章主音)
const CHAPTER_BASE_FREQ := {
	1: 110.0,  # A2
	2: 98.0,   # G2
	3: 87.31,  # F2
	4: 82.41,  # E2
	5: 73.42,  # D2
	6: 65.41,  # C2
	7: 58.27,  # A#1
}

const CHORD_PROGRESSION := [0, 7, 3, 10]  # 半音偏移
var _chord_index: int = 0
var _beat_counter: int = 0
var _sample_count: int = 0
var _samples_per_beat: int = 26460  # 44100 * 60 / 100 BPM


func _ready() -> void:
	_stream = AudioStreamGenerator.new()
	_stream.mix_rate = 44100
	_stream.buffer_length = 0.1
	_player = AudioStreamPlayer.new()
	_player.stream = _stream
	_player.volume_db = volume_db
	add_child(_player)


func play_chapter(chapter: int) -> void:
	_chapter = chapter
	_chord_index = 0
	_beat_counter = 0
	_sample_count = 0
	_phase = 0.0
	_is_playing = true
	_player.play()
	# play() 后才能 get_stream_playback()
	call_deferred("_capture_playback")


func _capture_playback() -> void:
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if _playback == null:
		# 可能需要重试
		await get_tree().create_timer(0.1).timeout
		_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback


func stop() -> void:
	_is_playing = false
	if _player and _player.playing:
		_player.stop()


func _process(_delta: float) -> void:
	if not _is_playing:
		return
	_fill_buffer()


func _fill_buffer() -> void:
	if _playback == null:
		return
	var frames_available = _playback.get_frames_available()
	for i in frames_available:
		_sample_count += 1
		var beat_pos = _sample_count % _samples_per_beat
		# 每 4 拍换一个和弦
		if beat_pos == 0:
			_chord_index = (_chord_index + 1) % CHORD_PROGRESSION.size()
		var freq = _get_current_freq()
		var envelope = _get_envelope(beat_pos)
		var sample = sin(_phase) * envelope * 0.25
		_playback.push_frame(Vector2(sample, sample))
		_phase += freq * TAU / 44100.0
		if _phase > TAU:
			_phase -= TAU


func _get_current_freq() -> float:
	var base_freq = CHAPTER_BASE_FREQ.get(_chapter, 110.0)
	var semitone = float(CHORD_PROGRESSION[_chord_index])
	return base_freq * pow(2.0, semitone / 12.0)


func _get_envelope(beat_pos: int) -> float:
	# 简单 attack-decay envelope
	var t = float(beat_pos) / float(_samples_per_beat)
	if t < 0.02:
		return t / 0.02
	else:
		return exp(-(t - 0.02) * 2.5)
