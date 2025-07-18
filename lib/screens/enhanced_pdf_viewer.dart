import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:jeezy/screens/notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

class EnhancedPDFViewerScreen extends StatefulWidget {
  final DriveFile file;
  final GoogleDriveService driveService;

  const EnhancedPDFViewerScreen({
    Key? key,
    required this.file,
    required this.driveService,
  }) : super(key: key);

  @override
  State<EnhancedPDFViewerScreen> createState() => _EnhancedPDFViewerScreenState();
}

class _EnhancedPDFViewerScreenState extends State<EnhancedPDFViewerScreen> 
    with TickerProviderStateMixin {
  
  // Core Controllers
  PdfViewerController? _pdfViewerController;
  late AnimationController _controlsAnimationController;
  late AnimationController _loadingController;
  late AnimationController _pageTransitionController;
  late Animation<double> _controlsAnimation;
  late Animation<double> _loadingAnimation;
  late Animation<Offset> _pageSlideAnimation;
  
  // State Variables
  File? _localFile;
  bool _isLoading = true;
  String? _error;
  bool _isFullscreen = false;
  bool _showControls = true;
  bool _isLandscape = false;
  Orientation? _currentOrientation;
  
  // Enhanced Display Modes
  bool _isDarkMode = false;
  bool _isNegativeMode = false;
  bool _isReaderMode = false;
  bool _isSepiaTone = false;
  double _brightness = 1.0;
  double _contrast = 1.0;
  double _textSize = 1.0;
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black;
  
  // PDF Properties
  int _currentPage = 1;
  int _totalPages = 0;
  double _readingProgress = 0.0;
  Duration _readingTime = Duration.zero;
  Timer? _readingTimer;
  Timer? _hideControlsTimer;
  Timer? _autoScrollTimer;
  
  // Enhanced Features
  List<int> _bookmarks = [];
  List<PDFAnnotation> _annotations = [];
  List<PDFHighlight> _highlights = [];
  List<PDFDrawing> _drawings = [];
  bool _isSpeaking = false;
  bool _isPaused = false;
  FlutterTts? _flutterTts;
  double _speechRate = 0.5;
  double _speechPitch = 1.0;
  double _speechVolume = 1.0;
  String _speechLanguage = 'en-US';
  List<String> _currentSentences = [];
  int _currentSentenceIndex = 0;
  
  // Search & Navigation
  bool _isSearching = false;
  String _searchQuery = '';
  bool _hasSearchResults = false;
  List<EnhancedPDFSearchResult> _searchResults = [];
  int _currentSearchIndex = 0;
  bool _caseSensitive = false;
  bool _wholeWords = false;
  TextEditingController _searchController = TextEditingController();
  SearchScope _searchScope = SearchScope.allPages;
  Timer? _searchDebounceTimer;
  
  // Enhanced Annotation System
  bool _isAnnotationMode = false;
  AnnotationType _selectedAnnotationType = AnnotationType.highlight;
  Color _selectedAnnotationColor = Colors.yellow;
  double _annotationOpacity = 0.5;
  String _annotationNote = '';
  bool _isDrawing = false;
  List<Offset> _currentDrawingPoints = [];
  GlobalKey _pdfKey = GlobalKey();
  
  // Layout & Performance
  PdfPageLayoutMode _layoutMode = PdfPageLayoutMode.continuous;
  PdfScrollDirection _scrollDirection = PdfScrollDirection.vertical;
  bool _enablePageSnapping = false;
  double _pageSpacing = 4.0;
  bool _isAutoScrolling = false;
  double _autoScrollSpeed = 1.0;
  ScrollController? _scrollController;
  
  // New Advanced Features
  bool _showThumbnails = false;
  List<Widget> _pageThumbnails = [];
  Map<String, dynamic> _readingStats = {};
  bool _autoBookmarkOnExit = false;
  bool _autoNightMode = false;
  TimeOfDay _nightModeStart = TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _nightModeEnd = TimeOfDay(hour: 6, minute: 0);
  
  // Performance Optimization
  final Map<int, Widget> _pageCache = {};
  int _cacheSize = 5;
  bool _preloadPages = true;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _scrollController = ScrollController();
    _initializeAnimations();
    _initializeTTS();
    _loadSavedSettings();
    _downloadAndOpenFile();
    _startReadingTimer();
    _checkAutoNightMode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (_currentOrientation != orientation) {
      _currentOrientation = orientation;
      _isLandscape = orientation == Orientation.landscape;
      _adaptToOrientation();
    }
  }

  void _adaptToOrientation() {
    setState(() {
      if (_isLandscape) {
        // Automatically enter fullscreen in landscape for better reading
        if (!_isFullscreen) {
          _toggleFullscreen();
        }
      }
    });
  }

  void _initializeAnimations() {
    _controlsAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    
    _loadingController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pageTransitionController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _controlsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controlsAnimationController, curve: Curves.easeOut),
    );
    
    _loadingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    
    _pageSlideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageTransitionController, curve: Curves.easeOut));
    
    _controlsAnimationController.forward();
    _loadingController.repeat();
  }

  Future<void> _initializeTTS() async {
    try {
      _flutterTts = FlutterTts();
      
      // Set up TTS callbacks for enhanced speech functionality
      _flutterTts!.setStartHandler(() {
        setState(() {
          _isSpeaking = true;
          _isPaused = false;
        });
      });
      
      _flutterTts!.setCompletionHandler(() {
        _onSentenceComplete();
      });
      
      _flutterTts!.setCancelHandler(() {
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
          _currentSentenceIndex = 0;
        });
      });
      
      _flutterTts!.setPauseHandler(() {
        setState(() {
          _isPaused = true;
        });
      });
      
      _flutterTts!.setContinueHandler(() {
        setState(() {
          _isPaused = false;
        });
      });
      
      _flutterTts!.setErrorHandler((msg) {
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
        });
        _showSnackBar('Speech error: $msg', Colors.red);
      });
      
      // Set initial TTS settings
      await _updateTTSSettings();
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  Future<void> _updateTTSSettings() async {
    if (_flutterTts == null) return;
    
    try {
      await _flutterTts!.setLanguage(_speechLanguage);
      await _flutterTts!.setSpeechRate(_speechRate);
      await _flutterTts!.setPitch(_speechPitch);
      await _flutterTts!.setVolume(_speechVolume);
    } catch (e) {
      print('Error updating TTS settings: $e');
    }
  }

  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fileKey = 'pdf_${widget.file.id}';
      
      setState(() {
        _isDarkMode = prefs.getBool('${fileKey}_dark_mode') ?? false;
        _isNegativeMode = prefs.getBool('${fileKey}_negative_mode') ?? false;
        _isReaderMode = prefs.getBool('${fileKey}_reader_mode') ?? false;
        _isSepiaTone = prefs.getBool('${fileKey}_sepia_tone') ?? false;
        _brightness = prefs.getDouble('${fileKey}_brightness') ?? 1.0;
        _contrast = prefs.getDouble('${fileKey}_contrast') ?? 1.0;
        _textSize = prefs.getDouble('${fileKey}_text_size') ?? 1.0;
        _speechRate = prefs.getDouble('${fileKey}_speech_rate') ?? 0.5;
        _speechPitch = prefs.getDouble('${fileKey}_speech_pitch') ?? 1.0;
        _speechVolume = prefs.getDouble('${fileKey}_speech_volume') ?? 1.0;
        _speechLanguage = prefs.getString('${fileKey}_speech_language') ?? 'en-US';
        _autoScrollSpeed = prefs.getDouble('${fileKey}_auto_scroll_speed') ?? 1.0;
        _pageSpacing = prefs.getDouble('${fileKey}_page_spacing') ?? 4.0;
        _enablePageSnapping = prefs.getBool('${fileKey}_page_snapping') ?? false;
        _preloadPages = prefs.getBool('${fileKey}_preload_pages') ?? true;
        _autoBookmarkOnExit = prefs.getBool('${fileKey}_auto_bookmark') ?? false;
        _autoNightMode = prefs.getBool('${fileKey}_auto_night_mode') ?? false;
        
        // Load reading time
        final savedReadingTime = prefs.getInt('${fileKey}_reading_time') ?? 0;
        _readingTime = Duration(seconds: savedReadingTime);
        
        // Load bookmarks
        final bookmarksJson = prefs.getString('${fileKey}_bookmarks');
        if (bookmarksJson != null) {
          final List<dynamic> bookmarksList = jsonDecode(bookmarksJson);
          _bookmarks = bookmarksList.cast<int>();
        }
        
        // Load annotations
        final annotationsJson = prefs.getString('${fileKey}_annotations');
        if (annotationsJson != null) {
          final List<dynamic> annotationsList = jsonDecode(annotationsJson);
          _annotations = annotationsList.map((json) => PDFAnnotation.fromJson(json)).toList();
        }
        
        // Load highlights
        final highlightsJson = prefs.getString('${fileKey}_highlights');
        if (highlightsJson != null) {
          final List<dynamic> highlightsList = jsonDecode(highlightsJson);
          _highlights = highlightsList.map((json) => PDFHighlight.fromJson(json)).toList();
        }
        
        // Load drawings
        final drawingsJson = prefs.getString('${fileKey}_drawings');
        if (drawingsJson != null) {
          final List<dynamic> drawingsList = jsonDecode(drawingsJson);
          _drawings = drawingsList.map((json) => PDFDrawing.fromJson(json)).toList();
        }
        
        _updateDisplayMode();
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fileKey = 'pdf_${widget.file.id}';
      
      await prefs.setBool('${fileKey}_dark_mode', _isDarkMode);
      await prefs.setBool('${fileKey}_negative_mode', _isNegativeMode);
      await prefs.setBool('${fileKey}_reader_mode', _isReaderMode);
      await prefs.setBool('${fileKey}_sepia_tone', _isSepiaTone);
      await prefs.setDouble('${fileKey}_brightness', _brightness);
      await prefs.setDouble('${fileKey}_contrast', _contrast);
      await prefs.setDouble('${fileKey}_text_size', _textSize);
      await prefs.setDouble('${fileKey}_speech_rate', _speechRate);
      await prefs.setDouble('${fileKey}_speech_pitch', _speechPitch);
      await prefs.setDouble('${fileKey}_speech_volume', _speechVolume);
      await prefs.setString('${fileKey}_speech_language', _speechLanguage);
      await prefs.setDouble('${fileKey}_auto_scroll_speed', _autoScrollSpeed);
      await prefs.setDouble('${fileKey}_page_spacing', _pageSpacing);
      await prefs.setBool('${fileKey}_page_snapping', _enablePageSnapping);
      await prefs.setBool('${fileKey}_preload_pages', _preloadPages);
      await prefs.setBool('${fileKey}_auto_bookmark', _autoBookmarkOnExit);
      await prefs.setBool('${fileKey}_auto_night_mode', _autoNightMode);
      await prefs.setInt('${fileKey}_reading_time', _readingTime.inSeconds);
      await prefs.setString('${fileKey}_bookmarks', jsonEncode(_bookmarks));
      await prefs.setString('${fileKey}_annotations', jsonEncode(_annotations.map((a) => a.toJson()).toList()));
      await prefs.setString('${fileKey}_highlights', jsonEncode(_highlights.map((h) => h.toJson()).toList()));
      await prefs.setString('${fileKey}_drawings', jsonEncode(_drawings.map((d) => d.toJson()).toList()));
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  void _updateDisplayMode() {
    if (_isDarkMode) {
      _backgroundColor = Color(0xFF121212);
      _textColor = Colors.white;
    } else if (_isSepiaTone) {
      _backgroundColor = Color(0xFFF4F1E8);
      _textColor = Color(0xFF5D4E37);
    } else if (_isReaderMode) {
      _backgroundColor = Color(0xFFFFFBF0);
      _textColor = Color(0xFF2C2C2C);
    } else {
      _backgroundColor = Colors.white;
      _textColor = Colors.black;
    }
  }

  void _checkAutoNightMode() {
    if (!_autoNightMode) return;
    final now = TimeOfDay.now();
    final isNightTime = _isTimeInRange(now, _nightModeStart, _nightModeEnd);
    
    if (isNightTime && !_isDarkMode) {
      setState(() {
        _isDarkMode = true;
        _updateDisplayMode();
      });
    } else if (!isNightTime && _isDarkMode) {
      setState(() {
        _isDarkMode = false;
        _updateDisplayMode();
      });
    }
  }

  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  Future<void> _downloadAndOpenFile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final file = await widget.driveService.downloadFile(
        widget.file.id,
        widget.file.name,
      );

      if (file != null) {
        _localFile = file;
        setState(() {
          _isLoading = false;
        });
        _loadingController.stop();
        
        // Preload first few pages for better performance
        if (_preloadPages) {
          _preloadNearbyPages();
        }
        
        // Generate thumbnails in background
        _generateThumbnails();
      } else {
        setState(() {
          _error = 'Failed to download PDF file';
          _isLoading = false;
        });
        _loadingController.stop();
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
      _loadingController.stop();
    }
  }

  void _preloadNearbyPages() {
    final startPage = math.max(1, _currentPage - 2);
    final endPage = math.min(_totalPages, _currentPage + 2);
    
    for (int i = startPage; i <= endPage; i++) {
      if (!_pageCache.containsKey(i)) {
        _pageCache[i] = Container(key: ValueKey('page_$i'));
      }
    }
    
    // Limit cache size
    if (_pageCache.length > _cacheSize) {
      final oldestKey = _pageCache.keys.first;
      _pageCache.remove(oldestKey);
    }
  }

  Future<void> _generateThumbnails() async {
    if (_localFile == null) return;
    
    try {
      // This would generate page thumbnails for navigation
      // Implementation depends on PDF processing capabilities
      _pageThumbnails = List.generate(_totalPages, (index) => 
        Container(
          key: ValueKey('thumb_$index'),
          width: 60,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: _textColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                color: _textColor,
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error generating thumbnails: $e');
    }
  }

  void _startReadingTimer() {
    _readingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isLoading && _localFile != null) {
        setState(() {
          _readingTime = Duration(seconds: _readingTime.inSeconds + 1);
        });
        
        // Update reading statistics
        _updateReadingStats();
        
        // Save reading time periodically
        if (_readingTime.inSeconds % 30 == 0) {
          _saveSettings();
        }
      }
    });
  }

  void _updateReadingStats() {
    _readingStats = {
      'totalTime': _readingTime.inMinutes,
      'pagesRead': _currentPage,
      'progress': _readingProgress,
      'averageTimePerPage': _currentPage > 0 ? _readingTime.inMinutes / _currentPage : 0,
      'estimatedTimeRemaining': _readingProgress > 0 
          ? (_readingTime.inMinutes / _readingProgress) * (1 - _readingProgress)
          : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        _isLandscape = orientation == Orientation.landscape;
        
        if (_isFullscreen || _isLandscape) {
          return _buildLandscapeView();
        }

        return _buildPortraitView();
      },
    );
  }

  Widget _buildLandscapeView() {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Row(
              children: [
                // PDF Content takes most space
                Expanded(
                  flex: _showControls && !_isFullscreen ? 3 : 4,
                  child: _buildPDFContent(),
                ),
                // Side panel for controls in landscape
                if (_showControls && !_isFullscreen)
                  Container(
                    width: 320,
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      border: Border(left: BorderSide(color: _textColor.withOpacity(0.2))),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(-2, 0),
                        ),
                      ],
                    ),
                    child: _buildLandscapeSidePanel(),
                  ),
              ],
            ),
            // Fullscreen controls overlay
            if (_isFullscreen && _showControls) _buildFullscreenControls(),
            if (_isAutoScrolling) _buildAutoScrollIndicator(),
            if (_showThumbnails) _buildThumbnailsPanel(),
          ],
        ),
      ),
    );
  }

    Widget _buildPortraitView() {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomControls(),
      floatingActionButton: _buildFloatingActionButtons(),
      drawer: _buildSettingsDrawer(),
    );
  }

  Widget _buildLandscapeSidePanel() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document info header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.file.name,
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.pages, size: 16, color: _textColor.withOpacity(0.7)),
                    SizedBox(width: 4),
                    Text(
                      'Page $_currentPage of $_totalPages',
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        color: _textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: _textColor.withOpacity(0.7)),
                    SizedBox(width: 4),
                    Text(
                      _formatDuration(_readingTime),
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        color: _textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _readingProgress,
                  backgroundColor: _textColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
                SizedBox(height: 4),
                Text(
                  '${(_readingProgress * 100).toInt()}% complete',
                  style: GoogleFonts.comicNeue(
                    fontSize: 11,
                    color: _textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Quick actions
          _buildLandscapeQuickActions(),
          
          SizedBox(height: 16),
          
          // Reading controls
          _buildLandscapeReadingControls(),
          
          SizedBox(height: 16),
          
          // Bookmarks
          if (_bookmarks.isNotEmpty) _buildLandscapeBookmarks(),
          
          SizedBox(height: 16),
          
          // Recent annotations
          if (_annotations.isNotEmpty || _highlights.isNotEmpty || _drawings.isNotEmpty) 
            _buildLandscapeAnnotations(),
        ],
      ),
    );
  }

  Widget _buildLandscapeQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _textColor,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildLandscapeActionChip(
              Icons.search,
              'Search',
              () => _showAdvancedSearchDialog(),
              isActive: _hasSearchResults,
            ),
            _buildLandscapeActionChip(
              _isSpeaking 
                  ? (_isPaused ? Icons.play_arrow : Icons.pause)
                  : Icons.record_voice_over,
              _isSpeaking 
                  ? (_isPaused ? 'Resume' : 'Pause')
                  : 'Read',
              () => _toggleTextToSpeech(),
              isActive: _isSpeaking,
            ),
            _buildLandscapeActionChip(
              _bookmarks.contains(_currentPage) ? Icons.bookmark : Icons.bookmark_border,
              'Bookmark',
              () => _toggleBookmark(),
              isActive: _bookmarks.contains(_currentPage),
            ),
            _buildLandscapeActionChip(
              Icons.fullscreen,
              'Fullscreen',
              () => _toggleFullscreen(),
            ),
            _buildLandscapeActionChip(
              _isAnnotationMode ? Icons.edit_off : Icons.edit,
              'Annotate',
              () => setState(() => _isAnnotationMode = !_isAnnotationMode),
              isActive: _isAnnotationMode,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLandscapeActionChip(IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
    return ActionChip(
      avatar: Icon(
        icon, 
        size: 16,
        color: isActive 
            ? Colors.white 
            : Theme.of(context).colorScheme.primary,
      ),
      label: Text(
        label, 
        style: GoogleFonts.comicNeue(
          fontSize: 12,
          color: isActive 
              ? Colors.white 
              : Theme.of(context).colorScheme.primary,
        ),
      ),
      onPressed: onTap,
      backgroundColor: isActive 
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.primary.withOpacity(0.1),
      elevation: isActive ? 4 : 0,
    );
  }

  Widget _buildLandscapeReadingControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading Controls',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _textColor,
          ),
        ),
        SizedBox(height: 12),
        
        // Page navigation
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _textColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _currentPage > 1 ? () => _pdfViewerController?.previousPage() : null,
                icon: Icon(Icons.skip_previous, color: _textColor),
                iconSize: 20,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _showJumpToPageDialog,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$_currentPage / $_totalPages',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _currentPage < _totalPages ? () => _pdfViewerController?.nextPage() : null,
                icon: Icon(Icons.skip_next, color: _textColor),
                iconSize: 20,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 12),
        
        // Auto-scroll controls
        Row(
          children: [
            Expanded(
              child: Text(
                'Auto Scroll',
                style: GoogleFonts.comicNeue(color: _textColor),
              ),
            ),
            Switch(
              value: _isAutoScrolling,
              onChanged: (value) => _toggleAutoScroll(),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        
        if (_isAutoScrolling) ...[
          SizedBox(height: 8),
          Text(
            'Speed: ${_autoScrollSpeed.toStringAsFixed(1)}x',
            style: GoogleFonts.comicNeue(
              fontSize: 12,
              color: _textColor.withOpacity(0.7),
            ),
          ),
          Slider(
            value: _autoScrollSpeed,
            min: 0.1,
            max: 3.0,
            divisions: 29,
            onChanged: (value) {
              setState(() {
                _autoScrollSpeed = value;
              });
              // Update auto-scroll speed immediately if active
              if (_isAutoScrolling) {
                _toggleAutoScroll(); // Stop
                _toggleAutoScroll(); // Restart with new speed
              }
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ],
    );
  }

  Widget _buildLandscapeBookmarks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bookmarks',
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _textColor,
              ),
            ),
            Text(
              '${_bookmarks.length}',
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                color: _textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _bookmarks.length,
            itemBuilder: (context, index) {
              final page = _bookmarks[index];
              final isCurrentPage = page == _currentPage;
              
              return GestureDetector(
                onTap: () => _pdfViewerController?.jumpToPage(page),
                child: Container(
                  width: 60,
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isCurrentPage 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : _textColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrentPage 
                          ? Theme.of(context).colorScheme.primary
                          : _textColor.withOpacity(0.2),
                      width: isCurrentPage ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark,
                        color: isCurrentPage 
                            ? Theme.of(context).colorScheme.primary
                            : _textColor.withOpacity(0.6),
                        size: 20,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$page',
                        style: GoogleFonts.comicNeue(
                          fontSize: 12,
                          fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentPage 
                              ? Theme.of(context).colorScheme.primary
                              : _textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeAnnotations() {
    final totalAnnotations = _annotations.length + _highlights.length + _drawings.length;
    final recentItems = <Widget>[];
    
    // Add recent annotations
    for (final annotation in _annotations.take(2)) {
      recentItems.add(_buildAnnotationPreview(annotation));
    }
    
    // Add recent highlights
    for (final highlight in _highlights.take(2)) {
      recentItems.add(_buildHighlightPreview(highlight));
    }
    
    // Add recent drawings
    for (final drawing in _drawings.take(1)) {
      recentItems.add(_buildDrawingPreview(drawing));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Notes',
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _textColor,
              ),
            ),
            GestureDetector(
              onTap: _showAnnotationsDialog,
              child: Text(
                'View All ($totalAnnotations)',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ...recentItems.take(3).toList(),
      ],
    );
  }

  Widget _buildAnnotationPreview(PDFAnnotation annotation) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: annotation.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: annotation.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getAnnotationIcon(annotation.type),
                size: 14,
                color: annotation.color,
              ),
              SizedBox(width: 4),
              Text(
                'Page ${annotation.page}',
                style: GoogleFonts.comicNeue(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            annotation.text,
            style: GoogleFonts.comicNeue(
              fontSize: 10,
              color: _textColor.withOpacity(0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (annotation.note != null) ...[
            SizedBox(height: 2),
            Text(
              annotation.note!,
              style: GoogleFonts.comicNeue(
                fontSize: 9,
                fontStyle: FontStyle.italic,
                color: _textColor.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightPreview(PDFHighlight highlight) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: highlight.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlight.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: highlight.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 4),
              Text(
                'Page ${highlight.page}',
                style: GoogleFonts.comicNeue(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            highlight.text,
            style: GoogleFonts.comicNeue(
              fontSize: 10,
              color: _textColor.withOpacity(0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingPreview(PDFDrawing drawing) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: drawing.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: drawing.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.brush,
            size: 14,
            color: drawing.color,
          ),
          SizedBox(width: 4),
          Text(
            'Drawing on Page ${drawing.page}',
            style: GoogleFonts.comicNeue(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _backgroundColor,
      foregroundColor: _textColor,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.file.name,
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (_totalPages > 0)
            Text(
              'Page $_currentPage of $_totalPages • ${(_readingProgress * 100).toInt()}% • ${_formatDuration(_readingTime)}',
              style: GoogleFonts.comicNeue(
                fontSize: 11,
                color: _textColor.withOpacity(0.7),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: _textColor),
          onPressed: _showAdvancedSearchDialog,
          tooltip: 'Advanced Search',
        ),
        IconButton(
          icon: Icon(
            _isSpeaking 
                ? (_isPaused ? Icons.play_arrow : Icons.pause)
                : Icons.record_voice_over,
            color: _isSpeaking ? Colors.green : _textColor,
          ),
          onPressed: _toggleTextToSpeech,
          tooltip: _isSpeaking 
              ? (_isPaused ? 'Resume Reading' : 'Pause Reading')
              : 'Read Aloud',
        ),
        IconButton(
          icon: Icon(
            _bookmarks.contains(_currentPage) ? Icons.bookmark : Icons.bookmark_border,
            color: _bookmarks.contains(_currentPage) ? Colors.orange : _textColor,
          ),
          onPressed: _toggleBookmark,
          tooltip: 'Toggle Bookmark',
        ),
        IconButton(
          icon: Icon(_isAnnotationMode ? Icons.edit_off : Icons.edit, color: _textColor),
          onPressed: () {
            setState(() {
              _isAnnotationMode = !_isAnnotationMode;
            });
          },
          tooltip: 'Annotation Mode',
        ),
        IconButton(
          icon: Icon(Icons.fullscreen, color: _textColor),
          onPressed: _toggleFullscreen,
          tooltip: 'Fullscreen',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: _textColor),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'auto_scroll',
              child: Row(
                children: [
                  Icon(_isAutoScrolling ? Icons.pause : Icons.play_arrow, size: 20),
                  SizedBox(width: 8),
                  Text(_isAutoScrolling ? 'Stop Auto Scroll' : 'Auto Scroll', style: GoogleFonts.comicNeue(color: _textColor, fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'thumbnails',
              child: Row(
                children: [
                  Icon(_showThumbnails ? Icons.view_module : Icons.view_module_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(_showThumbnails ? 'Hide Thumbnails' : 'Show Thumbnails', style: GoogleFonts.comicNeue(color: _textColor, fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'dark_mode',
              child: Row(
                children: [
                  Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, size: 20),
                  SizedBox(width: 8),
                  Text(_isDarkMode ? 'Light Mode' : 'Dark Mode', style: GoogleFonts.comicNeue(color: _textColor, fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'jump_to_page',
              child: Row(
                children: [
                  Icon(Icons.pages),
                  SizedBox(width: 8),
                  Text('Jump to Page', style: GoogleFonts.comicNeue(color: _textColor, fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'negative_mode',
              child: Row(
                children: [
                  Icon(_isNegativeMode ? Icons.invert_colors_off : Icons.invert_colors, size: 20),
                  SizedBox(width: 8),
                  Text(_isNegativeMode ? 'Normal Mode' : 'Negative Mode', style: GoogleFonts.comicNeue(color: _textColor, fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'reader_mode',
              child: Row(
                children: [
                  Icon(_isReaderMode ? Icons.chrome_reader_mode : Icons.chrome_reader_mode_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(_isReaderMode ? 'Exit Reader Mode' : 'Reader Mode', style: GoogleFonts.comicNeue(color: _textColor, fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'sepia_tone',
              child: Row(
                children: [
                  Icon(_isSepiaTone ? Icons.palette : Icons.palette_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(_isSepiaTone ? 'Normal Colors' : 'Sepia Tone', style: GoogleFonts.comicNeue(color: _textColor, fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'display_settings',
              child: Row(
                children: [
                  Icon(Icons.tune, size: 20),
                  SizedBox(width: 8),
                  Text('Display Settings', style: GoogleFonts.comicNeue(color: _textColor, fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'layout_options',
              child: Row(
                children: [
                  Icon(Icons.view_agenda, size: 20),
                  SizedBox(width: 8),
                  Text('Layout Options', style: GoogleFonts.comicNeue(color: _textColor, fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'speech_settings',
              child: Row(
                children: [
                  Icon(Icons.settings_voice, size: 20),
                  SizedBox(width: 8),
                  Text('Speech Settings', style: GoogleFonts.comicNeue(color: _textColor, fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'reading_stats',
              child: Row(
                children: [
                  Icon(Icons.analytics, size: 20),
                  SizedBox(width: 8),
                  Text('Reading Stats', style: GoogleFonts.comicNeue(color: _textColor, fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'bookmarks',
              child: Row(
                children: [
                  Icon(Icons.bookmarks, size: 20),
                  SizedBox(width: 8),
                  Text('View Bookmarks (${_bookmarks.length})', style: GoogleFonts.comicNeue(color: _textColor, fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'annotations',
              child: Row(
                children: [
                  Icon(Icons.note_add, size: 20),
                  SizedBox(width: 8),
                  Text('Annotations (${_annotations.length + _highlights.length + _drawings.length})', style: GoogleFonts.comicNeue(color: _textColor, fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        // Reading progress bar
        if (_totalPages > 0)
          Container(
            height: 4,
            child: LinearProgressIndicator(
              value: _readingProgress,
              backgroundColor: _textColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
          ),
        
        // Annotation toolbar
        if (_isAnnotationMode) _buildAnnotationToolbar(),
        
        // PDF Content
        Expanded(child: _buildPDFContent()),
        
        // Quick actions bar
        _buildQuickActionsBar(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: _backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _loadingAnimation,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading PDF...',
              style: GoogleFonts.comicNeue(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Preparing enhanced reading experience',
              style: GoogleFonts.comicNeue(
                color: _textColor.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(
              backgroundColor: _textColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildErrorState() {
    return Container(
      color: _backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!, style: GoogleFonts.comicNeue(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _downloadAndOpenFile,
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPDFContent() {
    if (_localFile == null) return Container();

    return Stack(
      key: _pdfKey,
      children: [
        Container(
          color: _backgroundColor,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(_getColorMatrix()),
            child: GestureDetector(
              onPanStart: _isAnnotationMode && _selectedAnnotationType == AnnotationType.drawing 
                  ? _onDrawingStart : null,
              onPanUpdate: _isAnnotationMode && _selectedAnnotationType == AnnotationType.drawing 
                  ? _onDrawingUpdate : null,
              onPanEnd: _isAnnotationMode && _selectedAnnotationType == AnnotationType.drawing 
                  ? _onDrawingEnd : null,
              onLongPressStart: _isAnnotationMode ? _onAnnotationLongPress : null,
              child: SfPdfViewer.file(
                _localFile!,
                controller: _pdfViewerController,
                scrollDirection: _scrollDirection,
                pageLayoutMode: _layoutMode,
                onPageChanged: (details) => _onPageChanged(details.newPageNumber),
                onDocumentLoaded: _onDocumentLoaded,
                onTextSelectionChanged: _isAnnotationMode ? _onTextSelectionChanged : null,
                enableDoubleTapZooming: !_isAnnotationMode,
                enableTextSelection: _isAnnotationMode,
                canShowScrollHead: !_isFullscreen,
                canShowScrollStatus: !_isFullscreen,
                canShowPaginationDialog: !_isFullscreen,
                enableDocumentLinkAnnotation: !_isAnnotationMode,
                enableHyperlinkNavigation: !_isAnnotationMode,
                pageSpacing: _pageSpacing,
              ),
            ),
          ),
        ),
        // Annotation overlay
        _buildAnnotationOverlay(),
        // Search highlight overlay
        if (_hasSearchResults) _buildSearchHighlightOverlay(),
        // Drawing overlay
        if (_isAnnotationMode && _selectedAnnotationType == AnnotationType.drawing)
          _buildDrawingOverlay(),
      ],
    );
  }

  Widget _buildAnnotationOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: CustomPaint(
          painter: AnnotationPainter(
            annotations: _annotations,
            highlights: _highlights,
            drawings: _drawings,
            currentPage: _currentPage,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHighlightOverlay() {
    if (_searchResults.isEmpty) return Container();
    
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: CustomPaint(
          painter: SearchHighlightPainter(_searchResults, _currentPage, _currentSearchIndex),
        ),
      ),
    );
  }

  Widget _buildDrawingOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: CustomPaint(
          painter: DrawingPainter(
            currentDrawing: _currentDrawingPoints,
            color: _selectedAnnotationColor,
            strokeWidth: 3.0,
          ),
        ),
      ),
    );
  }

  // Enhanced Annotation System
  void _onAnnotationLongPress(LongPressStartDetails details) {
    if (!_isAnnotationMode) return;

    final position = details.localPosition;
    
    switch (_selectedAnnotationType) {
      case AnnotationType.note:
        _showNoteDialog(position);
        break;
      case AnnotationType.highlight:
      case AnnotationType.underline:
      case AnnotationType.strikethrough:
        // These will be handled by text selection
        break;
      case AnnotationType.drawing:
        // Drawing is handled by pan gestures
        break;
      default:
        break;
    }
  }

  void _onTextSelectionChanged(PdfTextSelectionChangedDetails details) {
    if (!_isAnnotationMode || details.selectedText == null) return;
    
    // Automatically create annotation based on selected type
    switch (_selectedAnnotationType) {
      case AnnotationType.highlight:
        _createHighlightFromSelection(details);
        break;
      case AnnotationType.underline:
      case AnnotationType.strikethrough:
        _createAnnotationFromSelection(details);
        break;
      default:
        break;
    }
  }

  void _createHighlightFromSelection(PdfTextSelectionChangedDetails details) {
    final highlight = PDFHighlight(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      page: _currentPage,
      text: details.selectedText!,
      color: _selectedAnnotationColor,
      opacity: _annotationOpacity,
      createdAt: DateTime.now(),
      bounds: Rect.fromLTWH(100, 200, 200, 20), // Simplified bounds
    );
    
    setState(() {
      _highlights.add(highlight);
    });
    
    _saveSettings();
    _showSnackBar('Highlight added', _selectedAnnotationColor);
    
    // Clear selection
    Future.delayed(Duration(milliseconds: 500), () {
      _pdfViewerController?.clearSelection();
    });
  }

  void _createAnnotationFromSelection(PdfTextSelectionChangedDetails details) {
    final annotation = PDFAnnotation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      page: _currentPage,
      text: details.selectedText!,
      type: _selectedAnnotationType,
      color: _selectedAnnotationColor,
      opacity: _annotationOpacity,
      createdAt: DateTime.now(),
      bounds: Rect.fromLTWH(100, 200, 200, 20), // Simplified bounds
    );
    
    setState(() {
      _annotations.add(annotation);
    });
    
    _saveSettings();
    _showSnackBar('${_selectedAnnotationType.name.capitalize()} added', _selectedAnnotationColor);
    
    // Clear selection
    Future.delayed(Duration(milliseconds: 500), () {
      _pdfViewerController?.clearSelection();
    });
  }

  void _showNoteDialog(Offset position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        title: Text(
          'Add Note',
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Enter your note...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => _annotationNote = value,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_annotationNote.isNotEmpty) {
                _createNoteAnnotation(position);
                Navigator.pop(context);
              }
            },
            child: Text('Add Note'),
          ),
        ],
      ),
    );
  }

  void _createNoteAnnotation(Offset position) {
    final annotation = PDFAnnotation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      page: _currentPage,
      text: 'Note',
      type: AnnotationType.note,
      color: _selectedAnnotationColor,
      opacity: _annotationOpacity,
      createdAt: DateTime.now(),
      note: _annotationNote,
      bounds: Rect.fromLTWH(position.dx, position.dy, 20, 20),
    );
    
    setState(() {
      _annotations.add(annotation);
    });
    
    _saveSettings();
    _showSnackBar('Note added', _selectedAnnotationColor);
    _annotationNote = '';
  }

  // Drawing functionality
  void _onDrawingStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _currentDrawingPoints = [details.localPosition];
    });
  }

  void _onDrawingUpdate(DragUpdateDetails details) {
    if (_isDrawing) {
      setState(() {
        _currentDrawingPoints.add(details.localPosition);
      });
    }
  }

  void _onDrawingEnd(DragEndDetails details) {
    if (_isDrawing && _currentDrawingPoints.isNotEmpty) {
      final drawing = PDFDrawing(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        page: _currentPage,
        points: List.from(_currentDrawingPoints),
        color: _selectedAnnotationColor,
        strokeWidth: 3.0,
        createdAt: DateTime.now(),
      );
      
      setState(() {
        _drawings.add(drawing);
        _isDrawing = false;
        _currentDrawingPoints.clear();
      });
      
      _saveSettings();
      _showSnackBar('Drawing saved', _selectedAnnotationColor);
    }
  }

  Widget _buildAnnotationToolbar() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: _textColor.withOpacity(0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Annotation Mode',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            
            // Annotation type buttons
            ...AnnotationType.values.map((type) => Padding(
              padding: EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAnnotationType = type;
                  });
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedAnnotationType == type 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedAnnotationType == type 
                          ? Theme.of(context).colorScheme.primary
                          : _textColor.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    _getAnnotationIcon(type),
                    size: 20,
                    color: _selectedAnnotationType == type 
                        ? Colors.white
                        : _textColor,
                  ),
                ),
              ),
            )),
            
            SizedBox(width: 16),
            
            // Color picker
            ...([
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.red,
              Colors.purple,
              Colors.orange,
              Colors.pink,
              Colors.cyan,
            ].map((color) => GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAnnotationColor = color;
                });
                HapticFeedback.lightImpact();
              },
              child: Container(
                margin: EdgeInsets.only(right: 8),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedAnnotationColor == color 
                        ? Colors.black
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ))),
            
            SizedBox(width: 16),
            
            // Opacity control
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Opacity',
                  style: GoogleFonts.comicNeue(
                    fontSize: 10,
                    color: _textColor,
                  ),
                ),
                Container(
                  width: 80,
                  child: Slider(
                    value: _annotationOpacity,
                    onChanged: (value) {
                      setState(() {
                        _annotationOpacity = value;
                      });
                    },
                    min: 0.1,
                    max: 1.0,
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  '${(_annotationOpacity * 100).toInt()}%',
                  style: GoogleFonts.comicNeue(
                    fontSize: 9,
                    color: _textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border(
          top: BorderSide(
            color: _textColor.withOpacity(0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionButton(
            _isDarkMode ? Icons.light_mode : Icons.dark_mode,
            _isDarkMode ? 'Light' : 'Dark',
            () {
              setState(() {
                _isDarkMode = !_isDarkMode;
                if (_isDarkMode) {
                  _isReaderMode = false;
                  _isSepiaTone = false;
                  _isNegativeMode = false;
                }
                _updateDisplayMode();
              });
              _saveSettings();
            },
          ),
          _buildQuickActionButton(
            _isNegativeMode ? Icons.invert_colors_off : Icons.invert_colors,
            'Negative',
            () {
              setState(() {
                _isNegativeMode = !_isNegativeMode;
                if (_isNegativeMode) {
                  _isReaderMode = false;
                  _isSepiaTone = false;
                }
                _updateDisplayMode();
              });
              _saveSettings();
            },
          ),
          _buildQuickActionButton(
            _isReaderMode ? Icons.chrome_reader_mode : Icons.chrome_reader_mode_outlined,
            'Reader',
            () {
              setState(() {
                _isReaderMode = !_isReaderMode;
                if (_isReaderMode) {
                  _isSepiaTone = false;
                  _isNegativeMode = false;
                }
                _updateDisplayMode();
              });
              _saveSettings();
            },
          ),
          _buildQuickActionButton(
            Icons.bookmark_outline,
            'Bookmarks',
            () => _showBookmarksDialog(),
          ),
          _buildQuickActionButton(
            Icons.note_outlined,
            'Notes',
            () => _showAnnotationsDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: _textColor,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.comicNeue(
              fontSize: 10,
              color: _textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoScrollIndicator() {
    return Positioned(
      top: 100,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'Auto Scrolling',
              style: GoogleFonts.comicNeue(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '${_autoScrollSpeed.toStringAsFixed(1)}x',
              style: GoogleFonts.comicNeue(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailsPanel() {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border(right: BorderSide(color: _textColor.withOpacity(0.2))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: _textColor.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.view_module,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Pages',
                    style: GoogleFonts.comicNeue(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showThumbnails = false),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: _textColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  final pageNumber = index + 1;
                  final isCurrentPage = pageNumber == _currentPage;
                  final isBookmarked = _bookmarks.contains(pageNumber);
                  final hasAnnotations = _annotations.any((a) => a.page == pageNumber) ||
                                       _highlights.any((h) => h.page == pageNumber) ||
                                       _drawings.any((d) => d.page == pageNumber);
                  
                  return GestureDetector(
                    onTap: () => _pdfViewerController?.jumpToPage(pageNumber),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isCurrentPage 
                              ? Theme.of(context).colorScheme.primary
                              : _textColor.withOpacity(0.3),
                          width: isCurrentPage ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: isCurrentPage 
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            height: 80,
                            width: double.infinity,
                            child: Center(
                              child: Text(
                                '$pageNumber',
                                style: GoogleFonts.comicNeue(
                                  fontSize: 12,
                                  fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                                  color: isCurrentPage 
                                      ? Theme.of(context).colorScheme.primary
                                      : _textColor,
                                ),
                              ),
                            ),
                          ),
                          if (isBookmarked)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Icon(
                                Icons.bookmark,
                                size: 12,
                                color: Colors.orange,
                              ),
                            ),
                          if (hasAnnotations)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Icon(
                                Icons.note,
                                size: 12,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenControls() {
    return FadeTransition(
      opacity: _controlsAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.9),
            ],
            stops: [0.0, 0.25, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.fullscreen_exit, color: Colors.white),
                        onPressed: _toggleFullscreen,
                        tooltip: 'Exit Fullscreen',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.file.name,
                              style: GoogleFonts.comicNeue(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Page $_currentPage of $_totalPages • ${(_readingProgress * 100).toInt()}%',
                              style: GoogleFonts.comicNeue(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    
                    // Fullscreen action buttons
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _bookmarks.contains(_currentPage) ? Icons.bookmark : Icons.bookmark_border,
                              color: _bookmarks.contains(_currentPage) ? Colors.orange : Colors.white,
                            ),
                            onPressed: _toggleBookmark,
                            tooltip: 'Toggle Bookmark',
                          ),
                          IconButton(
                            icon: Icon(
                              _isSpeaking 
                                  ? (_isPaused ? Icons.play_arrow : Icons.pause)
                                  : Icons.record_voice_over,
                              color: _isSpeaking ? Colors.green : Colors.white,
                            ),
                            onPressed: _toggleTextToSpeech,
                            tooltip: _isSpeaking 
                                ? (_isPaused ? 'Resume Reading' : 'Pause Reading')
                                : 'Read Aloud',
                          ),
                          IconButton(
                            icon: Icon(Icons.search, color: Colors.white),
                            onPressed: _showAdvancedSearchDialog,
                            tooltip: 'Search',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Spacer(),
              
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.skip_previous, color: Colors.white),
                        onPressed: _currentPage > 1 ? () {
                          _pdfViewerController?.previousPage();
                        } : null,
                        tooltip: 'Previous Page',
                      ),
                    ),
                      GestureDetector(
                      onTap: _showJumpToPageDialog,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_currentPage / $_totalPages',
                          style: GoogleFonts.comicNeue(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.skip_next, color: Colors.white),
                        onPressed: _currentPage < _totalPages ? () {
                          _pdfViewerController?.nextPage();
                        } : null,
                        tooltip: 'Next Page',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border(
          top: BorderSide(
            color: _textColor.withOpacity(0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.first_page, color: _textColor),
            onPressed: () {
              _pdfViewerController?.jumpToPage(1);
            },
            tooltip: 'First Page',
          ),
          IconButton(
            icon: Icon(Icons.skip_previous, color: _textColor),
            onPressed: _currentPage > 1 ? () {
              _pdfViewerController?.previousPage();
            } : null,
            tooltip: 'Previous Page',
          ),
          Expanded(
            child: GestureDetector(
              onTap: _showJumpToPageDialog,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_currentPage / $_totalPages',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${(_readingProgress * 100).toInt()}% complete',
                      style: GoogleFonts.comicNeue(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.skip_next, color: _textColor),
            onPressed: _currentPage < _totalPages ? () {
              _pdfViewerController?.nextPage();
            } : null,
            tooltip: 'Next Page',
          ),
          IconButton(
            icon: Icon(Icons.last_page, color: _textColor),
            onPressed: () {
              _pdfViewerController?.jumpToPage(_totalPages);
            },
            tooltip: 'Last Page',
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_isSpeaking && !_isPaused)
          FloatingActionButton.small(
            heroTag: "pause_speech",
            onPressed: _pauseSpeech,
            backgroundColor: Colors.orange,
            child: Icon(Icons.pause),
            tooltip: 'Pause Reading',
          ),
        if (_isSpeaking && _isPaused)
          FloatingActionButton.small(
            heroTag: "resume_speech",
            onPressed: _resumeSpeech,
            backgroundColor: Colors.green,
            child: Icon(Icons.play_arrow),
            tooltip: 'Resume Reading',
          ),
        if (_isSpeaking)
          SizedBox(height: 8),
        if (_isSpeaking)
          FloatingActionButton.small(
            heroTag: "stop_speech",
            onPressed: _stopSpeech,
            backgroundColor: Colors.red,
            child: Icon(Icons.stop),
            tooltip: 'Stop Reading',
          ),
        if (_hasSearchResults && _searchQuery.isNotEmpty) ...[
          SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "search_clear",
            onPressed: () {
              _clearSearch();
            },
            backgroundColor: Colors.orange,
            child: Icon(Icons.clear),
            tooltip: 'Clear Search',
          ),
        ],
        SizedBox(height: 8),
        // FloatingActionButton(
        //   onPressed: _showJumpToPageDialog,
        //   backgroundColor: Theme.of(context).colorScheme.primary,
        //   child: Icon(Icons.pages),
        //   tooltip: 'Jump to Page',
        // ),
      ],
    );
  }

  // Enhanced Auto-scroll Implementation
  void _toggleAutoScroll() {
    if (_isAutoScrolling) {
      _autoScrollTimer?.cancel();
      setState(() {
        _isAutoScrolling = false;
      });
      _showSnackBar('Auto-scroll stopped', Colors.orange);
    } else {
      setState(() {
        _isAutoScrolling = true;
      });
      _startSmoothAutoScroll();
      _showSnackBar('Auto-scroll started', Colors.green);
    }
  }

  void _startSmoothAutoScroll() {
  // Use a different approach for smooth scrolling
  final intervalMs = 100; // 100ms intervals for smooth scrolling
  
  _autoScrollTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
    if (!_isAutoScrolling) {
      timer.cancel();
      return;
    }
    
    // Check if we've reached the end of the document
    if (_currentPage >= _totalPages) {
      _toggleAutoScroll(); // Stop auto-scroll at end
      return;
    }
    
    // Calculate scroll speed based on user setting
    // Higher speed = faster page transitions
    final scrollSpeed = _autoScrollSpeed;
    
    // Use a counter to control when to move to next page
    int scrollCounter = 0;
    scrollCounter++;
    
    // Move to next page based on scroll speed
    // Lower speed = longer delay between page changes
    final pageChangeInterval = (100 / scrollSpeed).round();
    
    if (scrollCounter >= pageChangeInterval) {
      scrollCounter = 0;
      
      // Smoothly transition to next page
      if (_currentPage < _totalPages) {
        _pdfViewerController?.nextPage();
      }
    }
  });
}


  // Advanced TTS Implementation
  Future<String> _extractTextFromCurrentPage() async {
    if (_pdfViewerController == null || _localFile == null) return '';
    
    try {
      final PdfDocument document = PdfDocument(inputBytes: await _localFile!.readAsBytes());
      
      if (_currentPage <= document.pages.count) {
        final String extractedText = PdfTextExtractor(document).extractText(
          startPageIndex: _currentPage - 1, 
          endPageIndex: _currentPage - 1
        );
        
        document.dispose();
        return _cleanExtractedText(extractedText);
      }
    } catch (e) {
      print('Error extracting text: $e');
    }
    
    return '';
  }

  String _cleanExtractedText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s.,!?;:\-()]'), '')
        .trim();
  }

  Future<void> _startAdvancedSpeech() async {
    try {
      final pageText = await _extractTextFromCurrentPage();
      if (pageText.isEmpty) {
        _showSnackBar('No text found on this page', Colors.orange);
        return;
      }

      setState(() {
        _isSpeaking = true;
        _isPaused = false;
        _currentSentenceIndex = 0;
      });

      _currentSentences = _splitIntoSentences(pageText);
      _speakCurrentSentence();
      
    } catch (e) {
      print('Error in advanced speech: $e');
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
      });
    }
  }

  List<String> _splitIntoSentences(String text) {
    return text.split(RegExp(r'[.!?]+'))
        .where((sentence) => sentence.trim().isNotEmpty)
        .map((sentence) => sentence.trim())
        .toList();
  }

  Future<void> _speakCurrentSentence() async {
    if (_currentSentenceIndex < _currentSentences.length && _isSpeaking) {
      final sentence = _currentSentences[_currentSentenceIndex];
      _highlightCurrentSentence(_currentSentenceIndex);
      await _flutterTts?.speak(sentence);
    } else {
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
        _currentSentenceIndex = 0;
      });
    }
  }

  void _onSentenceComplete() {
    if (_isSpeaking && !_isPaused) {
      setState(() {
        _currentSentenceIndex++;
      });
      
      Future.delayed(Duration(milliseconds: 200), () {
        _speakCurrentSentence();
      });
    }
  }

  void _highlightCurrentSentence(int sentenceIndex) {
    _showSnackBar(
      'Reading sentence ${sentenceIndex + 1} of ${_currentSentences.length}', 
      Colors.blue
    );
  }

  Future<void> _toggleTextToSpeech() async {
    if (_isSpeaking) {
      if (_isPaused) {
        await _resumeSpeech();
      } else {
        await _pauseSpeech();
      }
    } else {
      await _startAdvancedSpeech();
    }
  }

  Future<void> _pauseSpeech() async {
    await _flutterTts?.pause();
    setState(() {
      _isPaused = true;
    });
  }

  Future<void> _resumeSpeech() async {
    setState(() {
      _isPaused = false;
    });
    _speakCurrentSentence();
  }

  Future<void> _stopSpeech() async {
    await _flutterTts?.stop();
    setState(() {
      _isSpeaking = false;
      _isPaused = false;
      _currentSentenceIndex = 0;
      _currentSentences.clear();
    });
  }

  // Core functionality methods
  List<double> _getColorMatrix() {
    double b = (_brightness - 1.0) * 0.3;
    double c = _contrast;
    
    if (_isNegativeMode) {
      // Complete color inversion including PDF content
      return [
        -c, 0, 0, 0, 255 + b * 255,
        0, -c, 0, 0, 255 + b * 255,
        0, 0, -c, 0, 255 + b * 255,
        0, 0, 0, 1, 0,
      ];
    } else if (_isSepiaTone) {
      return [
        0.393 * c, 0.769 * c, 0.189 * c, 0, b * 255,
        0.349 * c, 0.686 * c, 0.168 * c, 0, b * 255,
        0.272 * c, 0.534 * c, 0.131 * c, 0, b * 255,
        0, 0, 0, 1, 0,
      ];
    } else {
      // Normal mode - no color filter on PDF content
      return [
        c, 0, 0, 0, b * 255,
        0, c, 0, 0, b * 255,
        0, 0, c, 0, b * 255,
        0, 0, 0, 1, 0,
      ];
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _readingProgress = _totalPages > 0 ? page / _totalPages : 0.0;
    });
    
    if (_isFullscreen) {
      _startHideControlsTimer();
    }
    
    if (_preloadPages) {
      _preloadNearbyPages();
    }
    
    if (_autoBookmarkOnExit && !_bookmarks.contains(page)) {
      if (page % 10 == 0 || _readingProgress > 0.5) {
        _bookmarks.add(page);
        _saveSettings();
      }
    }
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
    });
    _generateThumbnails();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      _startHideControlsTimer();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _showControls = true;
      _controlsAnimationController.forward();
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _controlsAnimationController.forward();
      if (_isFullscreen) {
        _startHideControlsTimer();
      }
    } else {
      _controlsAnimationController.reverse();
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(Duration(seconds: 5), () {
      if (_isFullscreen && _showControls && mounted) {
        _toggleControls();
      }
    });
  }

  void _toggleBookmark() {
    setState(() {
      if (_bookmarks.contains(_currentPage)) {
        _bookmarks.remove(_currentPage);
      } else {
        _bookmarks.add(_currentPage);
        _bookmarks.sort();
      }
    });
    
    _saveSettings();
    
    _showSnackBar(
      _bookmarks.contains(_currentPage) 
          ? 'Bookmark added for page $_currentPage'
          : 'Bookmark removed for page $_currentPage',
      _bookmarks.contains(_currentPage) ? Colors.green : Colors.orange,
    );
  }

  // Dialog methods
  void _showJumpToPageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int targetPage = _currentPage;
        return AlertDialog(
          backgroundColor: _backgroundColor,
          title: Text('Jump to Page', style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            color: _textColor,
          )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Page number (1-$_totalPages)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.pages),
                ),
                style: TextStyle(color: _textColor),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  targetPage = int.tryParse(value) ?? _currentPage;
                },
                autofocus: true,
              ),
              SizedBox(height: 16),
              LinearProgressIndicator(
                value: _readingProgress,
                backgroundColor: _textColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
              SizedBox(height: 8),
              Text(
                'Current: $_currentPage / $_totalPages (${(_readingProgress * 100).toInt()}%)',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  color: _textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (targetPage >= 1 && targetPage <= _totalPages) {
                  _pdfViewerController?.jumpToPage(targetPage);
                  Navigator.pop(context);
                }
              },
              child: Text('Jump'),
            ),
          ],
        );
      },
    );
  }

  void _showDisplaySettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        title: Text('Display Settings', style: GoogleFonts.comicNeue(
          fontWeight: FontWeight.bold,
          color: _textColor,
        )),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Brightness: ${(_brightness * 100).toInt()}%', 
                       style: GoogleFonts.comicNeue(color: _textColor)),
                  Slider(
                    value: _brightness,
                    min: 0.3,
                    max: 1.5,
                    divisions: 12,
                    onChanged: (value) {
                      setDialogState(() {
                        _brightness = value;
                      });
                      setState(() {});
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  
                  SizedBox(height: 16),
                  
                  Text('Contrast: ${(_contrast * 100).toInt()}%', 
                       style: GoogleFonts.comicNeue(color: _textColor)),
                  Slider(
                    value: _contrast,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    onChanged: (value) {
                      setDialogState(() {
                        _contrast = value;
                      });
                      setState(() {});
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  
                  SizedBox(height: 16),
                  
                  Text('Text Size: ${(_textSize * 100).toInt()}%', 
                       style: GoogleFonts.comicNeue(color: _textColor)),
                  Slider(
                    value: _textSize,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    onChanged: (value) {
                      setDialogState(() {
                        _textSize = value;
                      });
                      setState(() {});
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _brightness = 1.0;
                _contrast = 1.0;
                _textSize = 1.0;
              });
              _saveSettings();
            },
            child: Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveSettings();
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLayoutOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        title: Text('Layout Options', style: GoogleFonts.comicNeue(
          fontWeight: FontWeight.bold,
          color: _textColor,
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Page Layout',
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            SizedBox(height: 12),
            
            RadioListTile<PdfPageLayoutMode>(
              title: Row(
                children: [
                  Icon(Icons.view_agenda, size: 20, color: _textColor),
                  SizedBox(width: 8),
                  Text('Single Page', style: TextStyle(color: _textColor)),
                ],
              ),
              subtitle: Text(
                'Display one page at a time',
                style: TextStyle(color: _textColor.withOpacity(0.7)),
              ),
              value: PdfPageLayoutMode.single,
              groupValue: _layoutMode,
              onChanged: (value) {
                setState(() {
                  _layoutMode = value!;
                });
                Navigator.pop(context);
                _saveSettings();
              },
            ),
            
            RadioListTile<PdfPageLayoutMode>(
              title: Row(
                children: [
                  Icon(Icons.view_stream, size: 20, color: _textColor),
                  SizedBox(width: 8),
                  Text('Continuous', style: TextStyle(color: _textColor)),
                ],
              ),
              subtitle: Text(
                'Scroll through all pages continuously',
                style: TextStyle(color: _textColor.withOpacity(0.7)),
              ),
              value: PdfPageLayoutMode.continuous,
              groupValue: _layoutMode,
              onChanged: (value) {
                setState(() {
                  _layoutMode = value!;
                });
                Navigator.pop(context);
                _saveSettings();
              },
            ),
            
            SizedBox(height: 20),
            
            Text(
              'Scroll Direction',
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            SizedBox(height: 12),
            
            RadioListTile<PdfScrollDirection>(
              title: Row(
                children: [
                  Icon(Icons.swap_vert, size: 20, color: _textColor),
                  SizedBox(width: 8),
                  Text('Vertical', style: TextStyle(color: _textColor)),
                ],
              ),
              value: PdfScrollDirection.vertical,
              groupValue: _scrollDirection,
              onChanged: (value) {
                setState(() {
                  _scrollDirection = value!;
                });
                Navigator.pop(context);
                _saveSettings();
              },
            ),
            
            RadioListTile<PdfScrollDirection>(
              title: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 20, color: _textColor),
                  SizedBox(width: 8),
                  Text('Horizontal', style: TextStyle(color: _textColor)),
                ],
              ),
              value: PdfScrollDirection.horizontal,
              groupValue: _scrollDirection,
              onChanged: (value) {
                setState(() {
                  _scrollDirection = value!;
                });
                Navigator.pop(context);
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        title: Text('Bookmarks', style: GoogleFonts.comicNeue(
          fontWeight: FontWeight.bold,
          color: _textColor,
        )),
        content: _bookmarks.isEmpty
            ? Container(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 48, color: _textColor.withOpacity(0.5)),
                      SizedBox(height: 8),
                      Text('No bookmarks added yet', style: TextStyle(color: _textColor)),
                    ],
                  ),
                ),
              )
            : Container(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    final page = _bookmarks[index];
                    final isCurrentPage = page == _currentPage;
                    
                    return Card(
                      color: isCurrentPage 
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : _backgroundColor,
                      elevation: isCurrentPage ? 4 : 1,
                      child: ListTile(
                        leading: Icon(
                          Icons.bookmark, 
                          color: isCurrentPage 
                              ? Theme.of(context).colorScheme.primary
                              : Colors.orange,
                        ),
                        title: Text(
                          'Page $page',
                          style: GoogleFonts.comicNeue(
                            color: _textColor,
                            fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          isCurrentPage ? 'Current page' : 'Tap to navigate',
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            color: _textColor.withOpacity(0.7),
                          ),
                        ),
                        onTap: () {
                          _pdfViewerController?.jumpToPage(page);
                          Navigator.pop(context);
                        },
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _bookmarks.remove(page);
                            });
                            _saveSettings();
                            if (_bookmarks.isEmpty) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
                actions: [
          if (_bookmarks.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _bookmarks.clear();
                });
                _saveSettings();
                Navigator.pop(context);
              },
              child: Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAnnotationsDialog() {
    final totalAnnotations = _annotations.length + _highlights.length + _drawings.length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        title: Text('Annotations & Notes', style: GoogleFonts.comicNeue(
          fontWeight: FontWeight.bold,
          color: _textColor,
        )),
        content: totalAnnotations == 0
            ? Container(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_add_outlined, size: 48, color: _textColor.withOpacity(0.5)),
                      SizedBox(height: 8),
                      Text('No annotations added yet', style: TextStyle(color: _textColor)),
                    ],
                  ),
                ),
              )
            : Container(
                width: double.maxFinite,
                height: 400,
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: _textColor,
                        unselectedLabelColor: _textColor.withOpacity(0.6),
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        tabs: [
                          Tab(text: 'Annotations (${_annotations.length})'),
                          Tab(text: 'Highlights (${_highlights.length})'),
                          Tab(text: 'Drawings (${_drawings.length})'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Annotations tab
                            _annotations.isEmpty
                                ? Center(child: Text('No annotations', style: TextStyle(color: _textColor)))
                                : ListView.builder(
                                    itemCount: _annotations.length,
                                    itemBuilder: (context, index) {
                                      final annotation = _annotations[index];
                                      return Card(
                                        color: _backgroundColor,
                                        child: ListTile(
                                          leading: Icon(
                                            _getAnnotationIcon(annotation.type),
                                            color: annotation.color,
                                          ),
                                          title: Text(
                                            'Page ${annotation.page}',
                                            style: GoogleFonts.comicNeue(
                                              fontWeight: FontWeight.bold,
                                              color: _textColor,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                annotation.text,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: _textColor.withOpacity(0.7)),
                                              ),
                                              if (annotation.note != null)
                                                Text(
                                                  'Note: ${annotation.note}',
                                                  style: GoogleFonts.comicNeue(
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                    color: _textColor.withOpacity(0.6),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          onTap: () {
                                            _pdfViewerController?.jumpToPage(annotation.page);
                                            Navigator.pop(context);
                                          },
                                          trailing: IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _annotations.removeAt(index);
                                              });
                                              _saveSettings();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            // Highlights tab
                            _highlights.isEmpty
                                ? Center(child: Text('No highlights', style: TextStyle(color: _textColor)))
                                : ListView.builder(
                                    itemCount: _highlights.length,
                                    itemBuilder: (context, index) {
                                      final highlight = _highlights[index];
                                      return Card(
                                        color: _backgroundColor,
                                        child: ListTile(
                                          leading: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: highlight.color.withOpacity(highlight.opacity),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          title: Text(
                                            'Page ${highlight.page}',
                                            style: GoogleFonts.comicNeue(
                                              fontWeight: FontWeight.bold,
                                              color: _textColor,
                                            ),
                                          ),
                                          subtitle: Text(
                                            highlight.text,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: _textColor.withOpacity(0.7)),
                                          ),
                                          onTap: () {
                                            _pdfViewerController?.jumpToPage(highlight.page);
                                            Navigator.pop(context);
                                          },
                                          trailing: IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _highlights.removeAt(index);
                                              });
                                              _saveSettings();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            // Drawings tab
                            _drawings.isEmpty
                                ? Center(child: Text('No drawings', style: TextStyle(color: _textColor)))
                                : ListView.builder(
                                    itemCount: _drawings.length,
                                    itemBuilder: (context, index) {
                                      final drawing = _drawings[index];
                                      return Card(
                                        color: _backgroundColor,
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.brush,
                                            color: drawing.color,
                                          ),
                                          title: Text(
                                            'Drawing on Page ${drawing.page}',
                                            style: GoogleFonts.comicNeue(
                                              fontWeight: FontWeight.bold,
                                              color: _textColor,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Created: ${DateFormat('MMM dd, HH:mm').format(drawing.createdAt)}',
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 12,
                                              color: _textColor.withOpacity(0.7),
                                            ),
                                          ),
                                          onTap: () {
                                            _pdfViewerController?.jumpToPage(drawing.page);
                                            Navigator.pop(context);
                                          },
                                          trailing: IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _drawings.removeAt(index);
                                              });
                                              _saveSettings();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAdvancedSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Advanced Search',
                    style: GoogleFonts.comicNeue(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: _textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: _textColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _textColor.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.comicNeue(color: _textColor),
                  decoration: InputDecoration(
                    hintText: 'Search in document...',
                    hintStyle: GoogleFonts.comicNeue(color: _textColor.withOpacity(0.5)),
                    prefixIcon: _isSearching 
                        ? Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Icon(Icons.search, color: _textColor.withOpacity(0.7)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: _textColor.withOpacity(0.7)),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: _onSearchQueryChanged,
                ),
              ),
              SizedBox(height: 16),
              if (_searchResults.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _textColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_currentSearchIndex + 1} of ${_searchResults.length}',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _currentSearchIndex > 0 ? _previousSearchResult : null,
                            icon: Icon(Icons.keyboard_arrow_up),
                            tooltip: 'Previous result',
                          ),
                          IconButton(
                            onPressed: _currentSearchIndex < _searchResults.length - 1 ? _nextSearchResult : null,
                            icon: Icon(Icons.keyboard_arrow_down),
                            tooltip: 'Next result',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSearchQueryChanged(String query) {
    setState(() => _searchQuery = query);
    
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(Duration(milliseconds: 500), () {
      if (query.isNotEmpty && query.length >= 2) {
        _performAdvancedSearch(query);
      } else {
        setState(() {
          _searchResults.clear();
          _hasSearchResults = false;
        });
      }
    });
  }

  Future<void> _performAdvancedSearch(String query) async {
    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
      _searchResults.clear();
      _currentSearchIndex = 0;
    });

    try {
      final results = await _searchInDocument(query);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _hasSearchResults = results.isNotEmpty;
        if (results.isNotEmpty) {
          _currentSearchIndex = 0;
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _hasSearchResults = false;
      });
      print('Search error: $e');
    }
  }

  Future<List<EnhancedPDFSearchResult>> _searchInDocument(String query) async {
    if (_localFile == null) return [];
    
    try {
      final document = PdfDocument(inputBytes: await _localFile!.readAsBytes());
      final results = <EnhancedPDFSearchResult>[];
      
      for (int pageIndex = 0; pageIndex < document.pages.count; pageIndex++) {
        final pageText = PdfTextExtractor(document).extractText(
          startPageIndex: pageIndex,
          endPageIndex: pageIndex,
        );
        
        final pageResults = _findTextInPage(pageText, query, pageIndex + 1);
        results.addAll(pageResults);
      }
      
      document.dispose();
      return results;
    } catch (e) {
      print('Error searching document: $e');
      return [];
    }
  }

  List<EnhancedPDFSearchResult> _findTextInPage(String pageText, String query, int pageNumber) {
    final results = <EnhancedPDFSearchResult>[];
    
    String searchText = _caseSensitive ? pageText : pageText.toLowerCase();
    String searchQuery = _caseSensitive ? query : query.toLowerCase();
    
    final regex = RegExp(searchQuery, caseSensitive: _caseSensitive);
    final matches = regex.allMatches(searchText);
    
    for (int i = 0; i < matches.length; i++) {
      final match = matches.elementAt(i);
      final start = math.max(0, match.start - 50);
      final end = math.min(pageText.length, match.end + 50);
      final context = pageText.substring(start, end).trim();
      
      results.add(EnhancedPDFSearchResult(
        text: match.group(0) ?? query,
        pageNumber: pageNumber,
        bounds: Rect.fromLTWH(100.0, 200.0 + (i * 30), query.length * 8.0, 20.0),
        instanceIndex: i,
        context: context,
        matchStart: match.start - start,
        matchEnd: match.end - start,
      ));
    }
    
    return results;
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchResults.clear();
      _hasSearchResults = false;
      _currentSearchIndex = 0;
      _isSearching = false;
    });
    _searchController.clear();
    _pdfViewerController?.clearSelection();
  }

  void _nextSearchResult() {
    if (_currentSearchIndex < _searchResults.length - 1) {
      setState(() {
        _currentSearchIndex++;
      });
      _jumpToSearchResult(_searchResults[_currentSearchIndex]);
    }
  }

  void _previousSearchResult() {
    if (_currentSearchIndex > 0) {
      setState(() {
        _currentSearchIndex--;
      });
      _jumpToSearchResult(_searchResults[_currentSearchIndex]);
    }
  }

  void _jumpToSearchResult(EnhancedPDFSearchResult result) {
    _pdfViewerController?.jumpToPage(result.pageNumber);
  }

  void _showSpeechSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        title: Text('Speech Settings', style: GoogleFonts.comicNeue(
          fontWeight: FontWeight.bold,
          color: _textColor,
        )),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _speechLanguage,
                    decoration: InputDecoration(
                      labelText: 'Language',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'en-US', child: Text('English (US)')),
                      DropdownMenuItem(value: 'en-GB', child: Text('English (UK)')),
                      DropdownMenuItem(value: 'es-ES', child: Text('Spanish')),
                      DropdownMenuItem(value: 'fr-FR', child: Text('French')),
                      DropdownMenuItem(value: 'de-DE', child: Text('German')),
                      DropdownMenuItem(value: 'hi-IN', child: Text('Hindi')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _speechLanguage = value!;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Speech Rate: ${(_speechRate * 100).toInt()}%',
                    style: GoogleFonts.comicNeue(color: _textColor),
                  ),
                  Slider(
                    value: _speechRate,
                    min: 0.1,
                    max: 1.0,
                    divisions: 18,
                    onChanged: (value) {
                      setDialogState(() {
                        _speechRate = value;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Speech Pitch: ${(_speechPitch * 100).toInt()}%',
                    style: GoogleFonts.comicNeue(color: _textColor),
                  ),
                  Slider(
                    value: _speechPitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    onChanged: (value) {
                      setDialogState(() {
                        _speechPitch = value;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Volume: ${(_speechVolume * 100).toInt()}%',
                    style: GoogleFonts.comicNeue(color: _textColor),
                  ),
                  Slider(
                    value: _speechVolume,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    onChanged: (value) {
                      setDialogState(() {
                        _speechVolume = value;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateTTSSettings();
              await _saveSettings();
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReadingStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        title: Text('Reading Statistics', style: GoogleFonts.comicNeue(
          fontWeight: FontWeight.bold,
          color: _textColor,
        )),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Total Reading Time', _formatDuration(_readingTime)),
              _buildStatRow('Pages Read', '$_currentPage of $_totalPages'),
              _buildStatRow('Progress', '${(_readingProgress * 100).toInt()}%'),
              _buildStatRow('Average Time/Page', '${(_readingStats['averageTimePerPage'] ?? 0).toStringAsFixed(1)} min'),
              _buildStatRow('Bookmarks', '${_bookmarks.length}'),
              _buildStatRow('Annotations', '${_annotations.length}'),
              _buildStatRow('Highlights', '${_highlights.length}'),
              _buildStatRow('Drawings', '${_drawings.length}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.comicNeue(
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.comicNeue(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Settings Drawer
  Widget _buildSettingsDrawer() {
    return Drawer(
      backgroundColor: _backgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text(
                  'PDF Settings',
                  style: GoogleFonts.comicNeue(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Customize your reading experience',
                  style: GoogleFonts.comicNeue(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.file.name,
                  style: GoogleFonts.comicNeue(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Display Settings
          _buildSettingsSection('Display', [
            _buildSwitchTile(
              'Dark Mode',
              'Dark UI for comfortable reading',
              Icons.dark_mode,
              _isDarkMode,
              (value) {
                setState(() {
                  _isDarkMode = value;
                  if (_isDarkMode) {
                    _isReaderMode = false;
                    _isSepiaTone = false;
                  }
                  _updateDisplayMode();
                });
                _saveSettings();
              },
            ),
            _buildSwitchTile(
              'Negative Mode',
              'Invert all colors including PDF content',
              Icons.invert_colors,
              _isNegativeMode,
              (value) {
                setState(() {
                  _isNegativeMode = value;
                  if (_isNegativeMode) {
                    _isReaderMode = false;
                    _isSepiaTone = false;
                  }
                  _updateDisplayMode();
                });
                _saveSettings();
              },
            ),
            _buildSwitchTile(
              'Reader Mode',
              'Optimized layout for reading',
              Icons.chrome_reader_mode,
              _isReaderMode,
              (value) {
                setState(() {
                  _isReaderMode = value;
                  if (_isReaderMode) {
                    _isSepiaTone = false;
                    _isNegativeMode = false;
                  }
                  _updateDisplayMode();
                });
                _saveSettings();
              },
            ),
            _buildSwitchTile(
              'Sepia Tone',
              'Warm colors for eye comfort',
              Icons.palette,
              _isSepiaTone,
              (value) {
                setState(() {
                  _isSepiaTone = value;
                  if (_isSepiaTone) {
                    _isReaderMode = false;
                    _isNegativeMode = false;
                  }
                  _updateDisplayMode();
                });
                _saveSettings();
              },
            ),
          ]),
          
          // Reading Settings
          _buildSettingsSection('Reading', [
            _buildSwitchTile(
              'Auto Bookmark',
              'Automatically bookmark progress',
              Icons.bookmark_add,
              _autoBookmarkOnExit,
              (value) {
                setState(() {
                  _autoBookmarkOnExit = value;
                });
                _saveSettings();
              },
            ),
            _buildSwitchTile(
              'Preload Pages',
              'Preload nearby pages for smoother scrolling',
              Icons.cached,
              _preloadPages,
              (value) {
                setState(() {
                  _preloadPages = value;
                });
                _saveSettings();
              },
            ),
          ]),
          
          // Quick Actions
          _buildSettingsSection('Quick Actions', [
            ListTile(
              leading: Icon(Icons.analytics, color: _textColor),
              title: Text('Reading Statistics', style: TextStyle(color: _textColor, fontFamily: GoogleFonts.comicNeue().fontFamily)),
              onTap: () {
                Navigator.pop(context);
                _showReadingStats();
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_voice, color: _textColor),
              title: Text('Speech Settings', style: TextStyle(color: _textColor, fontFamily: GoogleFonts.comicNeue().fontFamily)),
              onTap: () {
                Navigator.pop(context);
                _showSpeechSettingsDialog();
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: GoogleFonts.comicNeue(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        Divider(color: _textColor.withOpacity(0.2)),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.comicNeue(color: _textColor)),
      subtitle: Text(subtitle, style: GoogleFonts.comicNeue(fontSize: 12, color: _textColor.withOpacity(0.7))),
      secondary: Icon(icon, color: _textColor),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  // Menu action handler
  void _handleMenuAction(String action) {
    switch (action) {
      case 'auto_scroll':
        _toggleAutoScroll();
        break;
      case 'thumbnails':
        setState(() => _showThumbnails = !_showThumbnails);
        break;
      case 'dark_mode':
        setState(() {
          _isDarkMode = !_isDarkMode;
          if (_isDarkMode) {
            _isReaderMode = false;
            _isSepiaTone = false;
          }
          _updateDisplayMode();
        });
        _saveSettings();
        break;
        case 'jump_to_page':
        _showJumpToPageDialog();
        break;
      case 'negative_mode':
        setState(() {
          _isNegativeMode = !_isNegativeMode;
          if (_isNegativeMode) {
            _isReaderMode = false;
            _isSepiaTone = false;
          }
          _updateDisplayMode();
        });
        _saveSettings();
        break;
      case 'reader_mode':
        setState(() {
          _isReaderMode = !_isReaderMode;
          if (_isReaderMode) {
            _isSepiaTone = false;
            _isNegativeMode = false;
          }
          _updateDisplayMode();
        });
        _saveSettings();
        break;
      case 'sepia_tone':
        setState(() {
          _isSepiaTone = !_isSepiaTone;
          if (_isSepiaTone) {
            _isReaderMode = false;
            _isNegativeMode = false;
          }
          _updateDisplayMode();
        });
        _saveSettings();
        break;
      case 'display_settings':
        _showDisplaySettingsDialog();
        break;
      case 'layout_options':
        _showLayoutOptionsDialog();
        break;
      case 'speech_settings':
        _showSpeechSettingsDialog();
        break;
      case 'reading_stats':
        _showReadingStats();
        break;
      case 'bookmarks':
        _showBookmarksDialog();
        break;
      case 'annotations':
        _showAnnotationsDialog();
        break;
    }
  }

  // Utility methods
  IconData _getAnnotationIcon(AnnotationType type) {
    switch (type) {
      case AnnotationType.highlight:
        return Icons.highlight;
      case AnnotationType.underline:
        return Icons.format_underlined;
      case AnnotationType.strikethrough:
        return Icons.format_strikethrough;
      case AnnotationType.note:
        return Icons.note_add;
      case AnnotationType.drawing:
        return Icons.brush;
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.comicNeue(color: Colors.white),
        ),
        backgroundColor: color,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _readingTimer?.cancel();
    _autoScrollTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _controlsAnimationController.dispose();
    _loadingController.dispose();
    _pageTransitionController.dispose();
    _flutterTts?.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _saveSettings();
    super.dispose();
  }
}

// Enhanced Models
class PDFAnnotation {
  final String id;
  final int page;
  final String text;
  final AnnotationType type;
  final Color color;
  final double opacity;
  final DateTime createdAt;
  final String? note;
  final Rect bounds;

  PDFAnnotation({
    required this.id,
    required this.page,
    required this.text,
    required this.type,
    required this.color,
    required this.opacity,
    required this.createdAt,
    this.note,
    required this.bounds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'page': page,
      'text': text,
      'type': type.index,
      'color': color.value,
      'opacity': opacity,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'note': note,
      'bounds': {
        'left': bounds.left,
        'top': bounds.top,
        'right': bounds.right,
        'bottom': bounds.bottom,
      },
    };
  }

  factory PDFAnnotation.fromJson(Map<String, dynamic> json) {
    final boundsData = json['bounds'] as Map<String, dynamic>;
    return PDFAnnotation(
      id: json['id'],
      page: json['page'],
      text: json['text'],
      type: AnnotationType.values[json['type']],
      color: Color(json['color']),
      opacity: json['opacity'] ?? 0.5,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      note: json['note'],
      bounds: Rect.fromLTRB(
        boundsData['left'],
        boundsData['top'],
        boundsData['right'],
        boundsData['bottom'],
      ),
    );
  }
}

class PDFHighlight {
  final String id;
  final int page;
  final String text;
  final Color color;
  final double opacity;
  final DateTime createdAt;
  final Rect bounds;

  PDFHighlight({
    required this.id,
    required this.page,
    required this.text,
    required this.color,
    required this.opacity,
    required this.createdAt,
    required this.bounds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'page': page,
      'text': text,
      'color': color.value,
      'opacity': opacity,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'bounds': {
        'left': bounds.left,
        'top': bounds.top,
        'right': bounds.right,
        'bottom': bounds.bottom,
      },
    };
  }

  factory PDFHighlight.fromJson(Map<String, dynamic> json) {
    final boundsData = json['bounds'] as Map<String, dynamic>;
    return PDFHighlight(
      id: json['id'],
      page: json['page'],
      text: json['text'],
      color: Color(json['color']),
      opacity: json['opacity'] ?? 0.5,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      bounds: Rect.fromLTRB(
        boundsData['left'],
        boundsData['top'],
        boundsData['right'],
        boundsData['bottom'],
      ),
    );
  }
}

class PDFDrawing {
  final String id;
  final int page;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DateTime createdAt;

  PDFDrawing({
    required this.id,
    required this.page,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'page': page,
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PDFDrawing.fromJson(Map<String, dynamic> json) {
    final pointsList = json['points'] as List<dynamic>;
    return PDFDrawing(
      id: json['id'],
      page: json['page'],
      points: pointsList.map((p) => Offset(p['dx'], p['dy'])).toList(),
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'] ?? 3.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}

class EnhancedPDFSearchResult {
  final String text;
  final int pageNumber;
  final Rect bounds;
  final int instanceIndex;
  final String context;
  final int matchStart;
  final int matchEnd;

  EnhancedPDFSearchResult({
    required this.text,
    required this.pageNumber,
    required this.bounds,
    required this.instanceIndex,
    required this.context,
    required this.matchStart,
    required this.matchEnd,
  });
}

enum AnnotationType {
  highlight,
  underline,
  strikethrough,
  note,
  drawing,
}

enum SearchScope { currentPage, allPages }

// Custom Painters for Annotations and Search Highlights
class AnnotationPainter extends CustomPainter {
  final List<PDFAnnotation> annotations;
  final List<PDFHighlight> highlights;
  final List<PDFDrawing> drawings;
  final int currentPage;

  AnnotationPainter({
    required this.annotations,
    required this.highlights,
    required this.drawings,
    required this.currentPage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw highlights
    final pageHighlights = highlights.where((h) => h.page == currentPage);
    for (final highlight in pageHighlights) {
      final paint = Paint()
        ..color = highlight.color.withOpacity(highlight.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(highlight.bounds, paint);
    }

    // Draw annotations
    final pageAnnotations = annotations.where((a) => a.page == currentPage);
    for (final annotation in pageAnnotations) {
      final paint = Paint()
        ..color = annotation.color.withOpacity(annotation.opacity);

      switch (annotation.type) {
        case AnnotationType.highlight:
          paint.style = PaintingStyle.fill;
          canvas.drawRect(annotation.bounds, paint);
          break;
        case AnnotationType.underline:
          paint.strokeWidth = 2;
          paint.style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(annotation.bounds.left, annotation.bounds.bottom),
            Offset(annotation.bounds.right, annotation.bounds.bottom),
            paint,
          );
          break;
        case AnnotationType.strikethrough:
          paint.strokeWidth = 2;
          paint.style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(annotation.bounds.left, annotation.bounds.center.dy),
            Offset(annotation.bounds.right, annotation.bounds.center.dy),
            paint,
          );
          break;
        case AnnotationType.note:
          paint.style = PaintingStyle.fill;
          canvas.drawCircle(
            annotation.bounds.center,
            8,
            paint,
          );
          break;
        default:
          break;
      }
    }

    // Draw drawings
    final pageDrawings = drawings.where((d) => d.page == currentPage);
    for (final drawing in pageDrawings) {
      final paint = Paint()
        ..color = drawing.color
        ..strokeWidth = drawing.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (drawing.points.isNotEmpty) {
        final path = Path();
        path.moveTo(drawing.points.first.dx, drawing.points.first.dy);
        
        for (int i = 1; i < drawing.points.length; i++) {
          path.lineTo(drawing.points[i].dx, drawing.points[i].dy);
        }
        
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SearchHighlightPainter extends CustomPainter {
  final List<EnhancedPDFSearchResult> searchResults;
  final int currentPage;
  final int currentSearchIndex;

  SearchHighlightPainter(this.searchResults, this.currentPage, this.currentSearchIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final pageResults = searchResults.where((r) => r.pageNumber == currentPage).toList();
    
    for (int i = 0; i < pageResults.length; i++) {
      final result = pageResults[i];
      final isCurrentResult = searchResults.indexOf(result) == currentSearchIndex;
      
      final paint = Paint()
        ..color = isCurrentResult 
            ? Colors.orange.withOpacity(0.7)
            : Colors.yellow.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(result.bounds, paint);
      
      if (isCurrentResult) {
        final borderPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRect(result.bounds, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawingPainter extends CustomPainter {
  final List<Offset> currentDrawing;
  final Color color;
  final double strokeWidth;

  DrawingPainter({
    required this.currentDrawing,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentDrawing.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(currentDrawing.first.dx, currentDrawing.first.dy);
    
    for (int i = 1; i < currentDrawing.length; i++) {
      path.lineTo(currentDrawing[i].dx, currentDrawing[i].dy);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
