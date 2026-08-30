import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ThalamApp());
}

class ThalamApp extends StatelessWidget {
  const ThalamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
      ],
      child: Consumer<UserProvider>(
        builder: (context, user, _) {
          return MaterialApp(
            title: 'Thalam Music',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF050505),
              primaryColor: const Color(0xFFD4AF37),
              textTheme: GoogleFonts.plusJakartaSansTextTheme(
                ThemeData.dark().textTheme,
              ),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFD4AF37),
                surface: Color(0xFF121218),
              ),
            ),
            home: user.isAuthenticated ? const MainShell() : const LoginScreen(),
          );
        },
      ),
    );
  }
}

enum UserRole { customer, vendor, admin }
enum EqPreset { balanced, acoustic, bassBoost, cinema, custom }
enum SurroundMode { off, music, spatial3D, liveConcert }

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String audioUrl;
  final String category;
  final bool isDownloaded;
  bool isLiked;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.audioUrl,
    this.category = 'Trending',
    this.isDownloaded = false,
    this.isLiked = false,
  });
}

class VendorSubmission {
  final String id;
  final String title;
  final String artist;
  final String genre;
  final String status;
  final DateTime submittedAt;

  VendorSubmission({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    this.status = 'Pending Review',
    required this.submittedAt,
  });

  VendorSubmission copyWith({String? status}) {
    return VendorSubmission(
      id: id,
      title: title,
      artist: artist,
      genre: genre,
      status: status ?? this.status,
      submittedAt: submittedAt,
    );
  }
}

class UserProvider extends ChangeNotifier {
  bool _isAuthenticated = true;
  UserRole _role = UserRole.customer;
  bool _isPremium = true;
  final String _userName = 'Thalam VIP Listener';
  String _userEmail = 'vaanivaai8@gmail.com';

  final Color goldAccent = const Color(0xFFD4AF37);
  final Color goldDark = const Color(0xFF8A6D3B);

  bool get isAuthenticated => _isAuthenticated;
  UserRole get role => _role;
  bool get isPremium => _isPremium;
  String get userName => _userName;
  String get userEmail => _userEmail;

  void setRole(UserRole newRole) {
    _role = newRole;
    notifyListeners();
  }

  void login(String email) {
    _isAuthenticated = true;
    _userEmail = email;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  void activatePremium() {
    _isPremium = true;
    notifyListeners();
  }
}

class MusicProvider extends ChangeNotifier {
  late final AudioPlayer _audioPlayer;
  late final AudioSession _session;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;

  List<Song> _playlist = [];
  int _currentIndex = 0;
  bool _isShuffle = false;
  bool _isRepeat = false;

  EqPreset _selectedPreset = EqPreset.bassBoost;
  List<double> _eqBands = [6.0, 4.0, 0.0, 2.0, 3.0];
  double _bassEngineLevel = 8.0;
  SurroundMode _surroundMode = SurroundMode.spatial3D;
  bool _is3dAudioEnabled = true;

  final List<VendorSubmission> _submissions = [
    VendorSubmission(
      id: 'sub_1',
      title: 'Malare (3D Spatial Remaster)',
      artist: 'Vijay Yesudas & Thalam',
      genre: 'Acoustic / Romantic',
      status: 'Pending Review',
      submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    VendorSubmission(
      id: 'sub_2',
      title: 'Aalaporan Thamizhan (Bass Cut)',
      artist: 'A.R. Rahman',
      genre: 'Folk / Anthem',
      status: 'Approved',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  MusicProvider() {
    _audioPlayer = AudioPlayer();
    _initCatalog();
    _initAudioSession();
  }

  AudioPlayer get player => _audioPlayer;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Song? get currentSong => _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;

  EqPreset get selectedPreset => _selectedPreset;
  List<double> get eqBands => _eqBands;
  double get bassEngineLevel => _bassEngineLevel;
  SurroundMode get surroundMode => _surroundMode;
  bool get is3dAudioEnabled => _is3dAudioEnabled;
  List<VendorSubmission> get submissions => _submissions;

  void _initCatalog() {
    _playlist = [
      Song(id: '1', title: 'Midnight Melodies (Spatial 3D)', artist: 'Arijit Singh, Thalam Originals', album: 'Acoustic Soul', duration: const Duration(minutes: 3, seconds: 45), audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', category: 'Trending', isLiked: true, isDownloaded: true),
      Song(id: '2', title: 'Neeyum Njanum (Master Mix)', artist: 'Sushin Shyam, Neha Nair', album: 'Kumbalangi Waves', duration: const Duration(minutes: 4, seconds: 12), audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', category: 'Trending', isLiked: true),
      Song(id: '3', title: 'Bass Surge EDM Blast', artist: 'Santhosh Narayanan', album: 'Raw Groove', duration: const Duration(minutes: 3, seconds: 15), audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', category: 'New Releases'),
      Song(id: '4', title: 'Illuminati (Acoustic Unplugged)', artist: 'Dabzee & Sushin', album: 'Sonic Waves', duration: const Duration(minutes: 3, seconds: 50), audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', category: 'New Releases', isDownloaded: true),
      Song(id: '5', title: 'Aromale (Spatial Sound)', artist: 'A.R. Rahman', album: 'Indie Thalam', duration: const Duration(minutes: 4, seconds: 20), audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', category: 'Recommendations'),
    ];
  }

  Future<void> _initAudioSession() async {
    _session = await AudioSession.instance;
    await _session.configure(const AudioSessionConfiguration.music());

    _interruptionSub = _session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (event.type == AudioInterruptionType.duck) {
          _audioPlayer.setVolume(0.3);
        } else {
          _audioPlayer.pause();
        }
      } else {
        if (event.type == AudioInterruptionType.duck) {
          _audioPlayer.setVolume(1.0);
        } else if (event.type == AudioInterruptionType.pause) {
          _audioPlayer.play();
        }
      }
    });

    _becomingNoisySub = _session.becomingNoisyEventStream.listen((_) {
      _audioPlayer.pause();
    });

    _audioPlayer.playerStateStream.listen((_) => notifyListeners());

    try {
      final sources = _playlist.map((s) => AudioSource.uri(Uri.parse(s.audioUrl), tag: s)).toList();
      final playlistSource = ConcatenatingAudioSource(children: sources);
      await _audioPlayer.setAudioSource(playlistSource, initialIndex: 0, initialPosition: Duration.zero);
    } catch (e) {
      debugPrint('Audio loading notice: $e');
    }
  }

  Future<void> playSong(int index) async {
    _currentIndex = index;
    if (await _session.setActive(true)) {
      try {
        await _audioPlayer.seek(Duration.zero, index: index);
        _audioPlayer.play();
      } catch (e) {
        debugPrint('Playback error: $e');
      }
    }
    notifyListeners();
  }

  void togglePlayPause() async {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      if (await _session.setActive(true)) {
        _audioPlayer.play();
      }
    }
    notifyListeners();
  }

  void next() {
    if (_audioPlayer.hasNext) {
      _audioPlayer.seekToNext();
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    } else {
      playSong(0);
    }
    notifyListeners();
  }

  void previous() {
    if (_audioPlayer.position.inSeconds > 3) {
      _audioPlayer.seek(Duration.zero);
    } else if (_audioPlayer.hasPrevious) {
      _audioPlayer.seekToPrevious();
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    } else {
      playSong(_playlist.length - 1);
    }
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    _audioPlayer.setShuffleModeEnabled(_isShuffle);
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    _audioPlayer.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  void toggleLike(String songId) {
    final idx = _playlist.indexWhere((s) => s.id == songId);
    if (idx != -1) {
      _playlist[idx].isLiked = !_playlist[idx].isLiked;
      notifyListeners();
    }
  }

  void setPreset(EqPreset preset) {
    _selectedPreset = preset;
    switch (preset) {
      case EqPreset.balanced: _eqBands = [0.0, 0.0, 0.0, 0.0, 0.0]; break;
      case EqPreset.acoustic: _eqBands = [2.0, 4.0, 3.0, 1.0, 2.0]; break;
      case EqPreset.bassBoost: _eqBands = [6.0, 4.0, 0.0, 2.0, 3.0]; break;
      case EqPreset.cinema: _eqBands = [5.0, 2.0, 2.0, 4.0, 6.0]; break;
      case EqPreset.custom: break;
    }
    notifyListeners();
  }

  void updateEqBand(int index, double value) {
    _eqBands[index] = value;
    _selectedPreset = EqPreset.custom;
    notifyListeners();
  }

  void setBassEngineLevel(double level) {
    _bassEngineLevel = level;
    notifyListeners();
  }

  void setSurroundMode(SurroundMode mode) {
    _surroundMode = mode;
    notifyListeners();
  }

  void toggle3dAudio(bool enabled) {
    _is3dAudioEnabled = enabled;
    notifyListeners();
  }

  void addVendorSubmission(String title, String artist, String genre) {
    _submissions.insert(0, VendorSubmission(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      artist: artist,
      genre: genre,
      submittedAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void updateSubmissionStatus(String id, String status) {
    final idx = _submissions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _submissions[idx] = _submissions[idx].copyWith(status: status);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _interruptionSub?.cancel();
    _becomingNoisySub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF050505),
      body: Center(child: Text("Login Screen", style: TextStyle(color: Colors.white))),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final accent = user.goldAccent;

    Widget currentScreen;
    if (user.role == UserRole.vendor) {
      currentScreen = const VendorScreen();
    } else if (user.role == UserRole.admin) {
      currentScreen = const AdminScreen();
    } else {
      switch (_selectedIndex) {
        case 0: currentScreen = const HomeScreen(); break;
        case 1: currentScreen = const SearchScreen(); break;
        case 2: currentScreen = const LibraryScreen(); break;
        case 3: currentScreen = const SoundEngineScreen(); break;
        case 4: currentScreen = const ProfileScreen(); break;
        default: currentScreen = const HomeScreen();
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('GOLDEN VIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: accent)),
              const SizedBox(width: 6),
              Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: accent))
            ]),
            const SizedBox(height: 2),
            const Text('Thalam Music', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          ],
        ),
        actions: [
          PopupMenuButton<UserRole>(
            initialValue: user.role,
            tooltip: 'Switch Mode',
            icon: Icon(Icons.switch_account_outlined, color: accent),
            onSelected: (role) {
              if (role == UserRole.admin) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
              } else {
                user.setRole(role);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: UserRole.customer, child: Text('Customer (Music Player)')),
              PopupMenuItem(value: UserRole.vendor, child: Text('Vendor (Upload Track)')),
              PopupMenuItem(value: UserRole.admin, child: Text('Admin (Login Required)')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF222228), border: Border.all(color: accent, width: 1.5)),
                  child: Center(child: Text('TL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent)))),
                Positioned(top: -2, right: -2, child: Container(width: 13, height: 13, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF3B82F6), border: Border.all(color: Colors.black, width: 1.5)),
                  child: const Center(child: Text('✓', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold))))),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          currentScreen,
          if (user.role == UserRole.customer)
            const Positioned(left: 0, right: 0, bottom: 0, child: PersistentMiniPlayer()),
        ],
      ),
      bottomNavigationBar: user.role == UserRole.customer
          ? Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x14FFFFFF), width: 1))),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (idx) => setState(() => _selectedIndex = idx),
                type: BottomNavigationBarType.fixed,
                backgroundColor: const Color(0xFF050505),
                selectedItemColor: accent,
                unselectedItemColor: Colors.white38,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
                  BottomNavigationBarItem(icon: Icon(Icons.queue_music), label: 'Library'),
                  BottomNavigationBarItem(icon: Icon(Icons.graphic_eq), label: 'Sound FX'),
                  BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
                ],
              ),
            )
          : null,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final user = context.watch<UserProvider>();
    final accent = user.goldAccent;

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 95),
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Trending In Kerala & Tamil Nadu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
        ]),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () {
            music.playSong(0);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FullPlayerScreen()));
          },
          child: Container(
            height: 280,
            decoration: BoxDecoration(color: const Color(0xFF0F0F14), borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0x14FFFFFF))),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent.withOpacity(0.25), width: 8)),
                    child: Center(
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                          border: Border.all(color: accent.withOpacity(0.4), width: 4),
                        ),
                        child: Icon(Icons.graphic_eq, size: 44, color: accent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SoundEngineScreen extends StatelessWidget {
  const SoundEngineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final user = context.watch<UserProvider>();
    final accent = user.goldAccent;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF14141C), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x14FFFFFF))),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Thalam Sub-Bass Engine', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Level ${music.bassEngineLevel.toInt()}/10', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
            ]),
            Slider(value: music.bassEngineLevel, min: 0, max: 10, divisions: 10, activeColor: accent, inactiveColor: Colors.white12,
              onChanged: (val) => music.setBassEngineLevel(val)),
            const Text('Hardware-level acoustic low-end enhancement for punchy bass.', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF14141C), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x14FFFFFF
                                                                                                                                                                   const Text('Hardware-level acoustic low-end enhancement for punchy bass.', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14141C),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Surround Sound Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: SurroundMode.values.map((mode) {
                    final isSel = music.surroundMode == mode;
                    return ChoiceChip(
                      label: Text(mode.name.toUpperCase(), style: TextStyle(fontSize: 11, color: isSel ? Colors.black : Colors.white)),
                      selected: isSel,
                      selectedColor: accent,
                      onSelected: (_) => music.setSurroundMode(mode),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PersistentMiniPlayer extends StatelessWidget {
  const PersistentMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final user = context.watch<UserProvider>();
    final song = music.currentSong;
    final accent = user.goldAccent;

    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FullPlayerScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF181820),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x14FFFFFF)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(song.title.substring(0, 2).toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${song.artist} • 03:45', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 22), onPressed: music.previous),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(music.player.playing ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 22),
                    onPressed: music.togglePlayPause,
                  ),
                ),
                IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 22), onPressed: music.next),
              ],
            ),
            const SizedBox(height: 6),
            StreamBuilder<Duration>(
              stream: music.player.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                final total = music.player.duration ?? song.duration;
                final progress = total.inMilliseconds > 0 ? (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0) : 0.0;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 2.5,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final user = context.watch<UserProvider>();
    final song = music.currentSong;
    final accent = user.goldAccent;

    if (song == null) return const Scaffold();

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 32), onPressed: () => Navigator.pop(context)),
        title: Column(
          children: [
            Text('PLAYING FROM THALAM', style: TextStyle(fontSize: 10, letterSpacing: 2, color: accent, fontWeight: FontWeight.bold)),
            Text(song.album, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 270,
              width: 270,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(colors: [user.goldDark, accent, const Color(0xFF1E1E28)]),
                border: Border.all(color: accent.withOpacity(0.5), width: 2),
                boxShadow: [BoxShadow(color: accent.withOpacity(0.2), blurRadius: 30, spreadRadius: 4)],
              ),
              child: Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                    border: Border.all(color: accent.withOpacity(0.4), width: 4),
                  ),
                  child: Icon(Icons.graphic_eq, size: 54, color: accent),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1),
                      const SizedBox(height: 4),
                      Text(song.artist, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1),
                    ],
                  ),
                ),
                IconButton(icon: Icon(song.isLiked ? Icons.favorite : Icons.favorite_border, color: song.isLiked ? accent : Colors.grey), onPressed: () => music.toggleLike(song.id)),
              ],
            ),
            StreamBuilder<Duration>(
              stream: music.player.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                final total = music.player.duration ?? song.duration;
                return Column(
                  children: [
                    Slider(
                      value: pos.inSeconds.toDouble().clamp(0.0, total.inSeconds.toDouble()),
                      max: total.inSeconds.toDouble(),
                      activeColor: accent,
                      inactiveColor: Colors.white24,
                      onChanged: (val) => music.player.seek(Duration(seconds: val.toInt())),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${pos.inMinutes}:${(pos.inSeconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          Text('${total.inMinutes}:${(total.inSeconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: Icon(Icons.shuffle, color: music.isShuffle ? accent : Colors.grey), onPressed: music.toggleShuffle),
                IconButton(icon: const Icon(Icons.skip_previous, size: 36), onPressed: music.previous),
                GestureDetector(
                  onTap: music.togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                    child: Icon(music.player.playing ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 36),
                  ),
                ),
                IconButton(icon: const Icon(Icons.skip_next, size: 36), onPressed: music.next),
                IconButton(icon: Icon(Icons.repeat, color: music.isRepeat ? accent : Colors.grey), onPressed: music.toggleRepeat),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF14141C), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.surround_sound, color: accent, size: 18),
                  const Text('3D Spatial Audio & Surround Active', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  Icon(Icons.verified, color: accent, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final results = music.playlist.where((s) => s.title.toLowerCase().contains(query.toLowerCase()) || s.artist.toLowerCase().contains(query.toLowerCase())).toList();

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 95),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: InputDecoration(
              hintText: 'Search songs, artists, raagas...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFF161622),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, idx) {
                final song = results[idx];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(song.title),
                  subtitle: Text('${song.artist} • ${song.album}'),
                  onTap: () => music.playSong(music.playlist.indexOf(song)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final user = context.watch<UserProvider>();
    final accent = user.goldAccent;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            indicatorColor: accent,
            labelColor: accent,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Downloads'),
              Tab(text: 'Liked Songs'),
              Tab(text: 'Playlists'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 95),
                  children: music.playlist.where((s) => s.isDownloaded).map((s) => ListTile(
                    leading: const Icon(Icons.download_done, color: Colors.green),
                    title: Text(s.title),
                    subtitle: Text(s.artist),
                    onTap: () => music.playSong(music.playlist.indexOf(s)),
                  )).toList(),
                ),
                ListView(
                  padding: const EdgeInsets.only(bottom: 95),
                  children: music.playlist.where((s) => s.isLiked).map((s) => ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.red),
                    title: Text(s.title),
                    subtitle: Text(s.artist),
                    onTap: () => music.playSong(music.playlist.indexOf(s)),
                  )).toList(),
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ListTile(
                      tileColor: const Color(0xFF161622),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: Icon(Icons.add_box, color: accent, size: 36),
                      title: const Text('Create New Playlist'),
                      subtitle: const Text('Curate your custom Spatial sound mix'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final accent = user.goldAccent;

    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 95),
      children: [
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: accent,
            child: const Text('TL', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(user.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        Center(child: Text(user.userEmail, style: const TextStyle(color: Colors.grey))),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161622),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Membership Tier', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('Thalam Golden VIP', style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const Icon(Icons.verified, color: Colors.blueAccent),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          onPressed: () => user.logout(),
        ),
      ],
    );
  }
}

class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key});

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  void _registerVendor() {
    if (_nameCtrl.text.isEmpty || _mobileCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    final music = context.read<MusicProvider>();
    music.addVendorSubmission(_nameCtrl.text, _mobileCtrl.text, _emailCtrl.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor Registered Successfully!')));
    _nameCtrl.clear();
    _mobileCtrl.clear();
    _emailCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final accent = user.goldAccent;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent.withOpacity(0.2), const Color(0xFF121218)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.5)),
          ),
          child: const Row(
            children: [
              CircleAvatar(radius: 25, backgroundColor: Colors.white, child: Icon(Icons.store, color: Colors.black)),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vendor Registration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Upload your music to Thalam', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text("Register as Vendor", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accent)),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'Name', prefixIcon: const Icon(Icons.person), filled: true, fillColor: const Color(0xFF161622), border: OutlineInputBorder
                                                                                     InputDecoration(labelText: 'Name', prefixIcon: const Icon(Icons.person), filled: true, fillColor: const Color(0xFF161622), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 12),
        TextField(controller: _mobileCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Mobile Number', prefixIcon: const Icon(Icons.phone), filled: true, fillColor: const Color(0xFF161622), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 12),
        TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email), filled: true, fillColor: const Color(0xFF161622), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black), onPressed: _registerVendor, child: const Text('Register & Upload Music', style: TextStyle(fontWeight: FontWeight.bold)))),
        const SizedBox(height: 24),
        Text("Your Submissions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accent)),
        const SizedBox(height: 12),
        ...context.watch<MusicProvider>().submissions.map((sub) {
          return Card(
            color: const Color(0xFF14141C),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: accent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.audio_file, color: accent)),
              title: Text(sub.title),
              subtitle: Text("${sub.artist} • ${sub.genre}"),
              trailing: Text(
                sub.status,
                style: TextStyle(
                  color: sub.status == 'Approved' ? Colors.green : (sub.status == 'Rejected' ? Colors.red : Colors.orange),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  void _login() {
    final user = context.read<UserProvider>();
    if (_userCtrl.text == 'ThalamMusic2026' && _passCtrl.text == 'Thalam@2026') {
      user.setRole(UserRole.admin);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Admin Credentials! Try again')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<UserProvider>().goldAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(title: const Text('Admin Login'), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, color: accent, size: 80),
            const SizedBox(height: 24),
            TextField(controller: _userCtrl, decoration: InputDecoration(labelText: 'Admin User ID', prefixIcon: const Icon(Icons.person), filled: true, fillColor: const Color(0xFF161622), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 16),
            TextField(controller: _passCtrl, obscureText: true, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock), filled: true, fillColor: const Color(0xFF161622), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black), onPressed: _login, child: const Text('Login as Admin', style: TextStyle(fontWeight: FontWeight.bold)))),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Customer App', style: TextStyle(color: Colors.white54))),
          ],
        ),
      ),
    );
  }
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final user = context.watch<UserProvider>();
    final accent = user.goldAccent;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent.withOpacity(0.2), const Color(0xFF121218)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 25, backgroundColor: Colors.white, child: Icon(Icons.shield, color: Colors.black)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thalam Control Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Administrator: ${user.userName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, "Total Songs", "${music.playlist.length}", Icons.music_note)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, "Pending Approvals", "${music.submissions.where((s) => s.status == 'Pending Review').length}", Icons.pending_actions)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, "Total Revenue", "₹50,000", Icons.currency_rupee)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, "Premium Users", "1,200", Icons.verified)),
          ],
        ),
        const SizedBox(height: 24),
        Text("Pending Song Approvals", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accent)),
        const SizedBox(height: 12),
        ...music.submissions.map((sub) {
          return Card(
            color: const Color(0xFF14141C),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: accent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.audio_file, color: accent)),
              title: Text(sub.title),
              subtitle: Text("${sub.artist} • ${sub.genre}"),
              trailing: DropdownButton<String>(
                value: sub.status,
                dropdownColor: const Color(0xFF14141C),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                underline: Container(height: 1, color: accent),
                items: const [
                  DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                  DropdownMenuItem(value: 'Pending Review', child: Text('Pending')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    music.updateSubmissionStatus(sub.id, val);
                  }
                },
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    final accent = context.watch<UserProvider>().goldAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14141C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }
}
