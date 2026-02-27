import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stroop_game/core/constants/game_constants.dart';
import 'package:stroop_game/core/notifications/notification_service.dart';
import 'package:stroop_game/data/repositories/stats_repository.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum GameMode { classic, timed, speed }

enum GameStatus { idle, playing, over }

enum AnswerResult { none, correct, incorrect }

// ── State ─────────────────────────────────────────────────────────────────────

class GameState {
  final String displayWord;
  final Color inkColor;
  final Color correctColor;
  final List<String> options;
  final int score;
  final int correct;
  final int total;
  final int timeLeftSeconds;
  final GameStatus status;
  final GameMode mode;
  final AnswerResult lastResult;
  final double currentSpeedMs;
  final int coinsEarnedThisSession;

  /// Whether the player had 0 coins when this game started (classic fallback).
  final bool startedWithZeroBalance;

  const GameState({
    this.displayWord = 'RED',
    this.inkColor = const Color(0xFF4F8EF7),
    this.correctColor = const Color(0xFFFF4757),
    this.options = const [],
    this.score = 0,
    this.correct = 0,
    this.total = 0,
    this.timeLeftSeconds = GameConstants.timedGameDuration,
    this.status = GameStatus.idle,
    this.mode = GameMode.classic,
    this.lastResult = AnswerResult.none,
    this.currentSpeedMs = 3000.0,
    this.coinsEarnedThisSession = 0,
    this.startedWithZeroBalance = false,
  });

  double get accuracy => total == 0 ? 0 : correct / total;

  GameState copyWith({
    String? displayWord,
    Color? inkColor,
    Color? correctColor,
    List<String>? options,
    int? score,
    int? correct,
    int? total,
    int? timeLeftSeconds,
    GameStatus? status,
    GameMode? mode,
    AnswerResult? lastResult,
    double? currentSpeedMs,
    int? coinsEarnedThisSession,
    bool? startedWithZeroBalance,
  }) {
    return GameState(
      displayWord: displayWord ?? this.displayWord,
      inkColor: inkColor ?? this.inkColor,
      correctColor: correctColor ?? this.correctColor,
      options: options ?? this.options,
      score: score ?? this.score,
      correct: correct ?? this.correct,
      total: total ?? this.total,
      timeLeftSeconds: timeLeftSeconds ?? this.timeLeftSeconds,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      lastResult: lastResult ?? this.lastResult,
      currentSpeedMs: currentSpeedMs ?? this.currentSpeedMs,
      coinsEarnedThisSession:
          coinsEarnedThisSession ?? this.coinsEarnedThisSession,
      startedWithZeroBalance:
          startedWithZeroBalance ?? this.startedWithZeroBalance,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final gameProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);

class GameNotifier extends Notifier<GameState> {
  final _rng = Random();
  Timer? _countdown;
  Timer? _speedTimer;
  Timer? _feedbackTimer;
  DateTime? _roundStart;
  DateTime? _gameStart; // for duration tracking
  bool _isTimedComplete = false; // true only when 60-sec timer naturally hits 0
  final List<double> _reactionTimes = [];

  @override
  GameState build() => const GameState();

  void startGame(GameMode mode) {
    _cancelAll();
    _reactionTimes.clear();
    _gameStart = DateTime.now();
    _isTimedComplete = false;

    final hadZeroBalance =
        mode == GameMode.classic &&
        StatsRepository.instance.getStats().coinBalance == 0;

    final first = _nextRoundState();
    state = first.copyWith(
      score: 0,
      correct: 0,
      total: 0,
      timeLeftSeconds: GameConstants.timedGameDuration,
      status: GameStatus.playing,
      mode: mode,
      lastResult: AnswerResult.none,
      currentSpeedMs: GameConstants.speedModeInitialMs.toDouble(),
      coinsEarnedThisSession: 0,
      startedWithZeroBalance: hadZeroBalance,
    );
    _roundStart = DateTime.now();
    if (mode == GameMode.timed) _startCountdown();
    if (mode == GameMode.speed) _startSpeedTimer(state.currentSpeedMs);
  }

  void submitAnswer(String word) {
    if (state.status != GameStatus.playing) return;
    _speedTimer?.cancel();

    final ms = _roundStart != null
        ? DateTime.now().difference(_roundStart!).inMilliseconds.toDouble()
        : 0.0;
    if (ms > 0) _reactionTimes.add(ms);

    final ok = word == state.displayWord;
    final newScore =
        (state.score +
                (ok
                    ? GameConstants.pointsCorrect
                    : GameConstants.pointsIncorrect))
            .clamp(0, 999999);
    final newCorrect = state.correct + (ok ? 1 : 0);
    final newTotal = state.total + 1;

    // Speed progression
    double spd = state.currentSpeedMs;
    if (state.mode == GameMode.speed && ok && newCorrect % 5 == 0) {
      spd = (spd - GameConstants.speedModeReductionMs).clamp(
        GameConstants.speedModeMinMs.toDouble(),
        double.infinity,
      );
    }

    state = state.copyWith(
      score: newScore,
      correct: newCorrect,
      total: newTotal,
      lastResult: ok ? AnswerResult.correct : AnswerResult.incorrect,
      currentSpeedMs: spd,
      // Live preview: estimate 2 coins per correct
      coinsEarnedThisSession: newCorrect * 2,
    );

    _feedbackTimer = Timer(const Duration(milliseconds: 380), () {
      if (state.status == GameStatus.playing) _advance();
    });
  }

  void endGame() {
    _cancelAll();
    state = state.copyWith(
      status: GameStatus.over,
      lastResult: AnswerResult.none,
    );
    _persist();
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  void _advance() {
    if (state.status != GameStatus.playing) return;
    final next = _nextRoundState();
    state = state.copyWith(
      displayWord: next.displayWord,
      inkColor: next.inkColor,
      correctColor: next.correctColor,
      options: next.options,
      lastResult: AnswerResult.none,
    );
    _roundStart = DateTime.now();
    if (state.mode == GameMode.speed) _startSpeedTimer(state.currentSpeedMs);
  }

  GameState _nextRoundState() {
    final words = List<String>.from(GameConstants.words);
    final word = words[_rng.nextInt(words.length)];
    String inkWord;
    do {
      inkWord = words[_rng.nextInt(words.length)];
    } while (inkWord == word);
    final opts = <String>[word];
    words.shuffle(_rng);
    for (final w in words) {
      if (opts.length == 4) break;
      if (w != word) opts.add(w);
    }
    opts.shuffle(_rng);
    return GameState(
      displayWord: word,
      inkColor: GameConstants.wordColors[inkWord]!,
      correctColor: GameConstants.wordColors[word]!,
      options: opts,
    );
  }

  void _startCountdown() {
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.status != GameStatus.playing) {
        t.cancel();
        return;
      }
      final left = state.timeLeftSeconds - 1;
      if (left <= 0) {
        t.cancel();
        // Mark as naturally completed AND set timeLeftSeconds = 0 before ending
        _isTimedComplete = true;
        state = state.copyWith(timeLeftSeconds: 0);
        endGame();
      } else {
        state = state.copyWith(timeLeftSeconds: left);
      }
    });
  }

  void _startSpeedTimer(double ms) {
    _speedTimer = Timer(Duration(milliseconds: ms.toInt()), () {
      if (state.status != GameStatus.playing) return;
      final newScore = (state.score + GameConstants.pointsIncorrect).clamp(
        0,
        999999,
      );
      state = state.copyWith(
        total: state.total + 1,
        score: newScore,
        lastResult: AnswerResult.incorrect,
      );
      _feedbackTimer = Timer(const Duration(milliseconds: 380), () {
        if (state.status == GameStatus.playing) _advance();
      });
    });
  }

  void _cancelAll() {
    _countdown?.cancel();
    _speedTimer?.cancel();
    _feedbackTimer?.cancel();
  }

  Future<void> _persist() async {
    final durationSeconds = _gameStart != null
        ? DateTime.now().difference(_gameStart!).inSeconds
        : 0;

    final earned = await StatsRepository.instance.awardCoins(
      mode: state.mode,
      score: state.score,
      correctCount: state.correct,
      accuracy: state.accuracy,
      durationSeconds: durationSeconds,
      isTimedComplete: _isTimedComplete,
      startedWithZeroBalance: state.startedWithZeroBalance,
    );

    // Update live display with actual persisted value
    state = state.copyWith(coinsEarnedThisSession: earned);

    // Fire a push notification showing the reward
    if (earned > 0) {
      final newBalance = StatsRepository.instance.getStats().coinBalance;
      final modeName = switch (state.mode) {
        GameMode.classic => 'Classic',
        GameMode.timed => '60 Seconds',
        GameMode.speed => 'Speed Run',
      };
      await NotificationService.instance.showGameReward(
        coinsEarned: earned,
        newBalance: newBalance,
        modeName: modeName,
      );
    }
  }
}
