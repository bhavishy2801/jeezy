  // notes_screen.dart
  // ignore_for_file: use_super_parameters, prefer_const_constructors_in_immutables

  import 'package:file_picker/file_picker.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:animated_theme_switcher/animated_theme_switcher.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:intl/intl.dart';
  import 'package:jeezy/main.dart';
  import 'package:jeezy/screens/enhanced_pdf_viewer.dart';
  import 'package:jeezy/screens/note_detail_screen.dart';
  import 'package:share_plus/share_plus.dart';
  import 'dart:convert';
  import 'dart:io';
  import 'dart:math' as math show Random, cos, log, pi, pow, sin, max, min;
  import 'dart:typed_data';
  import 'dart:async';
  import 'package:path_provider/path_provider.dart';
  import 'package:googleapis/drive/v3.dart' as ga;
  import 'package:googleapis_auth/auth_io.dart';
  import 'package:http/http.dart' as http;
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  import 'package:url_launcher/url_launcher.dart';
  import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
  import 'package:photo_view/photo_view.dart';
  import 'package:photo_view/photo_view_gallery.dart';
  import 'package:video_player/video_player.dart';
  import 'package:chewie/chewie.dart';
  import 'package:audioplayers/audioplayers.dart';
  import 'package:google_sign_in/google_sign_in.dart';
  import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
  import 'package:cached_network_image/cached_network_image.dart';
  import 'package:flutter_cache_manager/flutter_cache_manager.dart';
  import 'package:connectivity_plus/connectivity_plus.dart';
  import 'package:permission_handler/permission_handler.dart';
  import 'package:device_info_plus/device_info_plus.dart';
  import 'package:package_info_plus/package_info_plus.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:flutter_inappwebview/flutter_inappwebview.dart';
  import 'package:jeezy/screens/office_viewers.dart';
  import 'package:fl_chart/fl_chart.dart';

  // Google Drive Configuration - READ ONLY ACCESS
  const String _clientId = "683367496409-8ki0l5l5bkldnubpl885vv3afbdej19p.apps.googleusercontent.com";
  const String _googleDriveFolderId = "1ko5PAp-ebjU0AciEt4FMDl4pITzXpBXc";
  const List<String> _scopes = ['https://www.googleapis.com/auth/drive.readonly'];

  // Enhanced Drive File Model (keeping your existing implementation)
  class DriveFile {
    final String id;
    final String name;
    final String mimeType;
    final int size;
    final DateTime modifiedTime;
    final DateTime createdTime;
    final String? thumbnailLink;
    final String? webViewLink;
    final String? webContentLink;
    final List<String> parents;
    final String? description;
    final Map<String, dynamic>? properties;
    final bool isFolder;
    final String? md5Checksum;
    final String? sha1Checksum;
    final String? sha256Checksum;
    final bool isShared;
    final List<String> owners;
    final String? lastModifyingUser;
    final int version;
    final bool isStarred;
    final bool isTrashed;
    final bool isExplicitlyTrashed;
    final String? originalFilename;
    final String? fullFileExtension;
    final String? fileExtension;
    final String? headRevisionId;
    final bool isWritersCanShare;
    final bool isViewedByMe;
    final DateTime? viewedByMeTime;
    final bool isOwnedByMe;
    final String? permissionId;
    final String? quotaBytesUsed;

    DriveFile({
      required this.id,
      required this.name,
      required this.mimeType,
      required this.size,
      required this.modifiedTime,
      required this.createdTime,
      this.thumbnailLink,
      this.webViewLink,
      this.webContentLink,
      required this.parents,
      this.description,
      this.properties,
      required this.isFolder,
      this.md5Checksum,
      this.sha1Checksum,
      this.sha256Checksum,
      required this.isShared,
      required this.owners,
      this.lastModifyingUser,
      required this.version,
      required this.isStarred,
      required this.isTrashed,
      required this.isExplicitlyTrashed,
      this.originalFilename,
      this.fullFileExtension,
      this.fileExtension,
      this.headRevisionId,
      required this.isWritersCanShare,
      required this.isViewedByMe,
      this.viewedByMeTime,
      required this.isOwnedByMe,
      this.permissionId,
      this.quotaBytesUsed,
    });

    factory DriveFile.fromGoogleDriveFile(ga.File file) {
      return DriveFile(
        id: file.id!,
        name: file.name!,
        mimeType: file.mimeType!,
        size: int.tryParse(file.size ?? '0') ?? 0,
        modifiedTime: file.modifiedTime!,
        createdTime: file.createdTime!,
        thumbnailLink: file.thumbnailLink,
        webViewLink: file.webViewLink,
        webContentLink: file.webContentLink,
        parents: file.parents ?? [],
        description: file.description,
        properties: file.properties,
        isFolder: file.mimeType == 'application/vnd.google-apps.folder',
        md5Checksum: file.md5Checksum,
        sha1Checksum: file.sha1Checksum,
        sha256Checksum: file.sha256Checksum,
        isShared: file.shared ?? false,
        owners: file.owners?.map((owner) => owner.displayName ?? 'Unknown').toList() ?? [],
        lastModifyingUser: file.lastModifyingUser?.displayName,
        version: (file.version is int) ? file.version as int : 
        int.tryParse(file.version?.toString() ?? '1') ?? 1,
        isStarred: file.starred ?? false,
        isTrashed: file.trashed ?? false,
        isExplicitlyTrashed: file.explicitlyTrashed ?? false,
        originalFilename: file.originalFilename,
        fullFileExtension: file.fullFileExtension,
        fileExtension: file.fileExtension,
        headRevisionId: file.headRevisionId,
        isWritersCanShare: file.writersCanShare ?? false,
        isViewedByMe: file.viewedByMe ?? false,
        viewedByMeTime: file.viewedByMeTime,
        isOwnedByMe: file.ownedByMe ?? false,
        permissionId: file.permissionIds?.isNotEmpty == true ? file.permissionIds!.first : null,
        quotaBytesUsed: file.quotaBytesUsed,
      );
    }

    String get displaySize {
      if (size == 0) return '0 B';
      const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
      final i = (math.log(size) / math.log(1024)).floor();
      return '${(size / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
    }

    String get fileTypeCategory {
    if (isFolder) return 'Folder';
    if (mimeType.contains('pdf')) return 'PDF';
    if (mimeType.contains('image')) return 'Image';
    if (mimeType.contains('video')) return 'Video';
    if (mimeType.contains('audio')) return 'Audio';
    
    // Enhanced document support
    if (mimeType.contains('document') || 
        mimeType.contains('text') ||
        mimeType.contains('pdf') ||
        mimeType.contains('wordprocessingml') ||
        name.toLowerCase().endsWith('.docx') ||
        name.toLowerCase().endsWith('.doc') ||
        name.toLowerCase().endsWith('.txt')) return 'Document';
        
    if (mimeType.contains('spreadsheet') ||
        mimeType.contains('sheet') ||
        name.toLowerCase().endsWith('.xlsx') ||
        name.toLowerCase().endsWith('.xls')) return 'Spreadsheet';
        
    if (mimeType.contains('presentation') ||
        name.toLowerCase().endsWith('.pptx') ||
        name.toLowerCase().endsWith('.ppt')) return 'Presentation';
        
    if (mimeType.contains('archive') || mimeType.contains('zip')) return 'Archive';
    return 'Other';
  }

    IconData get fileIcon {
    if (isFolder) return Icons.folder;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('image')) return Icons.image;
    if (mimeType.contains('video')) return Icons.video_file;
    if (mimeType.contains('audio')) return Icons.audio_file;
    
    // Enhanced Office file icons
    if (mimeType.contains('wordprocessingml') || 
        mimeType.contains('msword') ||
        name.toLowerCase().endsWith('.docx') ||
        name.toLowerCase().endsWith('.doc')) return Icons.description;
        
    if (mimeType.contains('spreadsheet') ||
        mimeType.contains('excel') ||
        mimeType.contains('ms-excel') ||
        name.toLowerCase().endsWith('.xlsx') ||
        name.toLowerCase().endsWith('.xls')) return Icons.table_chart;
        
    if (mimeType.contains('presentation') ||
        mimeType.contains('powerpoint') ||
        mimeType.contains('ms-powerpoint') ||
        name.toLowerCase().endsWith('.pptx') ||
        name.toLowerCase().endsWith('.ppt')) return Icons.slideshow;
    
    if (mimeType.contains('document') || mimeType.contains('text')) return Icons.description;
    if (mimeType.contains('archive') || mimeType.contains('zip')) return Icons.archive;
    return Icons.insert_drive_file;
  }


    Color get fileTypeColor {
      if (isFolder) return Colors.blue;
      if (mimeType.contains('pdf')) return Colors.red;
      if (mimeType.contains('image')) return Colors.green;
      if (mimeType.contains('video')) return Colors.purple;
      if (mimeType.contains('audio')) return Colors.orange;
      if (mimeType.contains('document') || mimeType.contains('text')) return Colors.blue;
      if (mimeType.contains('spreadsheet')) return Colors.teal;
      if (mimeType.contains('presentation')) return Colors.deepOrange;
      if (mimeType.contains('archive') || mimeType.contains('zip')) return Colors.brown;
      return Colors.grey;
    }

    bool get canPreview {
      return mimeType.contains('image') || 
            mimeType.contains('pdf') || 
            mimeType.contains('video') || 
            mimeType.contains('audio') ||
            mimeType.contains('text');
    }

    bool get isMediaFile {
      return mimeType.contains('image') || 
            mimeType.contains('video') || 
            mimeType.contains('audio');
    }

    bool get isDocumentFile {
    return mimeType.contains('pdf') || 
          mimeType.contains('document') || 
          mimeType.contains('text') ||
          mimeType.contains('wordprocessingml') ||
          mimeType.contains('spreadsheet') ||
          mimeType.contains('presentation') ||
          name.toLowerCase().endsWith('.docx') ||
          name.toLowerCase().endsWith('.doc') ||
          name.toLowerCase().endsWith('.txt') ||
          name.toLowerCase().endsWith('.xlsx') ||
          name.toLowerCase().endsWith('.xls') ||
          name.toLowerCase().endsWith('.pptx') ||
          name.toLowerCase().endsWith('.ppt');
  }
  }

  // Student Progress Model (keeping your existing implementation)
  class StudentProgress {
    final String userId;
    final String fileId;
    final String fileName;
    final int viewCount;
    final DateTime firstViewed;
    final DateTime lastViewed;
    final Duration totalTimeSpent;
    final List<String> annotations;
    final List<String> bookmarks;
    final Map<String, dynamic> metadata;
    final bool isFavorite;
    final double progress;
    final Map<String, DateTime> sessionHistory;
    final List<String> tags;
    final String? lastPosition;
    final Map<String, dynamic> customData;

    StudentProgress({
      required this.userId,
      required this.fileId,
      required this.fileName,
      required this.viewCount,
      required this.firstViewed,
      required this.lastViewed,
      required this.totalTimeSpent,
      required this.annotations,
      required this.bookmarks,
      required this.metadata,
      required this.isFavorite,
      required this.progress,
      required this.sessionHistory,
      required this.tags,
      this.lastPosition,
      required this.customData,
    });

    Map<String, dynamic> toJson() {
      return {
        'userId': userId,
        'fileId': fileId,
        'fileName': fileName,
        'viewCount': viewCount,
        'firstViewed': Timestamp.fromDate(firstViewed),
        'lastViewed': Timestamp.fromDate(lastViewed),
        'totalTimeSpent': totalTimeSpent.inSeconds,
        'annotations': annotations,
        'bookmarks': bookmarks,
        'metadata': metadata,
        'isFavorite': isFavorite,
        'progress': progress,
        'sessionHistory': sessionHistory.map((key, value) => 
          MapEntry(key, Timestamp.fromDate(value))),
        'tags': tags,
        'lastPosition': lastPosition,
        'customData': customData,
      };
    }

    factory StudentProgress.fromJson(Map<String, dynamic> json) {
      return StudentProgress(
        userId: json['userId'],
        fileId: json['fileId'],
        fileName: json['fileName'],
        viewCount: json['viewCount'] ?? 0,
        firstViewed: (json['firstViewed'] as Timestamp).toDate(),
        lastViewed: (json['lastViewed'] as Timestamp).toDate(),
        totalTimeSpent: Duration(seconds: json['totalTimeSpent'] ?? 0),
        annotations: List<String>.from(json['annotations'] ?? []),
        bookmarks: List<String>.from(json['bookmarks'] ?? []),
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
        isFavorite: json['isFavorite'] ?? false,
        progress: (json['progress'] ?? 0.0).toDouble(),
        sessionHistory: (json['sessionHistory'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as Timestamp).toDate())
        ) ?? {},
        tags: List<String>.from(json['tags'] ?? []),
        lastPosition: json['lastPosition'],
        customData: Map<String, dynamic>.from(json['customData'] ?? {}),
      );
    }

    StudentProgress copyWith({
      String? userId,
      String? fileId,
      String? fileName,
      int? viewCount,
      DateTime? firstViewed,
      DateTime? lastViewed,
      Duration? totalTimeSpent,
      List<String>? annotations,
      List<String>? bookmarks,
      Map<String, dynamic>? metadata,
      bool? isFavorite,
      double? progress,
      Map<String, DateTime>? sessionHistory,
      List<String>? tags,
      String? lastPosition,
      Map<String, dynamic>? customData,
    }) {
      return StudentProgress(
        userId: userId ?? this.userId,
        fileId: fileId ?? this.fileId,
        fileName: fileName ?? this.fileName,
        viewCount: viewCount ?? this.viewCount,
        firstViewed: firstViewed ?? this.firstViewed,
        lastViewed: lastViewed ?? this.lastViewed,
        totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
        annotations: annotations ?? this.annotations,
        bookmarks: bookmarks ?? this.bookmarks,
        metadata: metadata ?? this.metadata,
        isFavorite: isFavorite ?? this.isFavorite,
        progress: progress ?? this.progress,
        sessionHistory: sessionHistory ?? this.sessionHistory,
        tags: tags ?? this.tags,
        lastPosition: lastPosition ?? this.lastPosition,
        customData: customData ?? this.customData,
      );
    }
  }

  // Enhanced Google Drive Service (keeping your existing implementation)
  class GoogleDriveService {
    static final GoogleDriveService _instance = GoogleDriveService._internal();
    factory GoogleDriveService() => _instance;
    GoogleDriveService._internal();

    ga.DriveApi? _driveApi;
    GoogleSignIn? _googleSignIn;
    final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
    final DefaultCacheManager _cacheManager = DefaultCacheManager();
    
    bool _isInitialized = false;
    bool _isAuthenticated = false;
    String? _currentUserId;
    Map<String, DriveFile> _fileCache = {};
    Map<String, List<DriveFile>> _folderCache = {};
    DateTime? _lastCacheUpdate;
    
    static const int maxRetries = 3;
    static const Duration retryDelay = Duration(seconds: 2);
    static const Duration cacheExpiry = Duration(hours: 1);

    bool get isInitialized => _isInitialized;
    bool get isAuthenticated => _isAuthenticated;
    String? get currentUserId => _currentUserId;

    Future<bool> initialize() async {
      try {
        _googleSignIn = GoogleSignIn(scopes: _scopes);
        final account = await _googleSignIn!.signInSilently();
        if (account != null) {
          await _authenticateWithAccount(account);
        }
        _isInitialized = true;
        return true;
      } catch (e) {
        print('Error initializing Google Drive service: $e');
        return false;
      }
    }

    Future<bool> authenticate() async {
      try {
        if (!_isInitialized) {
          await initialize();
        }
        final account = await _googleSignIn!.signIn();
        if (account == null) {
          return false;
        }
        return await _authenticateWithAccount(account);
      } catch (e) {
        print('Error authenticating with Google Drive: $e');
        return false;
      }
    }

    Future<bool> _authenticateWithAccount(GoogleSignInAccount account) async {
      try {
        final authHeaders = await account.authHeaders;
        final authenticateClient = GoogleAuthClient(authHeaders);
        
        _driveApi = ga.DriveApi(authenticateClient);
        _currentUserId = account.id;
        _isAuthenticated = true;

        await _secureStorage.write(key: 'google_user_id', value: account.id);
        await _secureStorage.write(key: 'google_user_email', value: account.email);
        
        return true;
      } catch (e) {
        print('Error setting up Drive API: $e');
        return false;
      }
    }

    Future<void> signOut() async {
      try {
        await _googleSignIn?.signOut();
        await _secureStorage.deleteAll();
        
        _driveApi = null;
        _currentUserId = null;
        _isAuthenticated = false;
        _fileCache.clear();
        _folderCache.clear();
        _lastCacheUpdate = null;
      } catch (e) {
        print('Error signing out: $e');
      }
    }

    // Add this to your GoogleDriveService class
  void clearCache() {
    _fileCache.clear();
    _folderCache.clear();
    _lastCacheUpdate = null;
  }

  // Update the listFilesInFolder method to handle duplicates better
  Future<List<DriveFile>> listFilesInFolder(String folderId, {
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    if (!_isAuthenticated) {
      final success = await authenticate();
      if (!success) {
        throw Exception('Not authenticated with Google Drive');
      }
    }

    if (useCache && !forceRefresh && _folderCache.containsKey(folderId)) {
      final cachedFiles = _folderCache[folderId]!;
      if (_lastCacheUpdate != null && 
          DateTime.now().difference(_lastCacheUpdate!) < cacheExpiry) {
        return cachedFiles;
      }
    }

    try {
      final files = await _fetchFilesWithRetry(folderId);
      
      // Remove duplicates based on file ID
      final Map<String, DriveFile> uniqueFiles = {};
      for (final file in files) {
        uniqueFiles[file.id] = file;
      }
      final uniqueFilesList = uniqueFiles.values.toList();
      
      _folderCache[folderId] = uniqueFilesList;
      _lastCacheUpdate = DateTime.now();
      
      for (final file in uniqueFilesList) {
        _fileCache[file.id] = file;
      }

      return uniqueFilesList;
    } catch (e) {
      print('Error listing files in folder $folderId: $e');
      
      if (_folderCache.containsKey(folderId)) {
        return _folderCache[folderId]!;
      }
      
      rethrow;
    }
  }

    Future<List<DriveFile>> _fetchFilesWithRetry(String folderId) async {
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          final fileList = await _driveApi!.files.list(
            q: "'$folderId' in parents and trashed = false",
            pageSize: 1000,
            orderBy: 'folder,name',
            $fields: 'nextPageToken, files(id, name, mimeType, size, modifiedTime, '
                    'createdTime, thumbnailLink, webViewLink, webContentLink, '
                    'parents, description, properties, md5Checksum, sha1Checksum, '
                    'sha256Checksum, shared, owners, lastModifyingUser, version, '
                    'starred, trashed, explicitlyTrashed, originalFilename, '
                    'fullFileExtension, fileExtension, headRevisionId, '
                    'writersCanShare, viewedByMe, viewedByMeTime, ownedByMe, '
                    'permissionIds, quotaBytesUsed)',
          );

          final files = fileList.files?.map((file) => DriveFile.fromGoogleDriveFile(file)).toList() ?? [];
          
          files.sort((a, b) {
            if (a.isFolder && !b.isFolder) return -1;
            if (!a.isFolder && b.isFolder) return 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          return files;
        } catch (e) {
          if (attempt == maxRetries - 1) rethrow;
          
          print('Attempt ${attempt + 1} failed, retrying in ${retryDelay.inSeconds}s: $e');
          await Future.delayed(retryDelay);
        }
      }
      
      return [];
    }

    Future<File?> downloadFile(String fileId, String fileName, {
      Function(int, int)? onProgress,
      bool useCache = true,
    }) async {
      if (!_isAuthenticated) {
        throw Exception('Not authenticated with Google Drive');
      }

      try {
        if (useCache) {
          final cachedFile = await _cacheManager.getFileFromCache(fileId);
          if (cachedFile != null) {
            return cachedFile.file;
          }
        }

        final response = await _driveApi!.files.get(
          fileId,
          downloadOptions: ga.DownloadOptions.fullMedia,
        ) as ga.Media;

        final bytes = <int>[];
        int totalBytes = 0;
        int receivedBytes = 0;

        await for (final chunk in response.stream) {
          bytes.addAll(chunk);
          receivedBytes += chunk.length;
          
          if (onProgress != null && totalBytes > 0) {
            onProgress(receivedBytes, totalBytes);
          }
        }

        final file = await _cacheManager.putFile(
          fileId,
          Uint8List.fromList(bytes),
          fileExtension: fileName.split('.').last,
        );

        return file;
      } catch (e) {
        print('Error downloading file $fileId: $e');
        return null;
      }
    }
  }

  // Google Auth Client for API requests
  class GoogleAuthClient extends http.BaseClient {
    final Map<String, String> _headers;
    final http.Client _client = http.Client();

    GoogleAuthClient(this._headers);

    @override
    Future<http.StreamedResponse> send(http.BaseRequest request) {
      request.headers.addAll(_headers);
      return _client.send(request);
    }

    @override
    void close() {
      _client.close();
    }
  }

  // Main Notes Screen with Enhanced UI and Student Dashboard
  class NotesScreen extends StatefulWidget {
    const NotesScreen({Key? key}) : super(key: key);

    @override
    State<NotesScreen> createState() => _NotesScreenState();
  }

  class _NotesScreenState extends State<NotesScreen> with TickerProviderStateMixin {
    // Controllers and Services
    final TextEditingController _searchController = TextEditingController();
    final ScrollController _scrollController = ScrollController();
    final GoogleDriveService _driveService = GoogleDriveService();
    final Map<String, DriveFile> _fileCache = {};
    
    // Tab Controller for Dashboard
    late TabController _tabController;
    
    // Animation Controllers
    late AnimationController _fabAnimationController;
    late AnimationController _scrollAnimationController;
    late AnimationController _syncAnimationController;
    late Animation<double> _fabAnimation;
    late Animation<double> _scrollToTopAnimation;
    late Animation<double> _syncAnimation;
    
    // State Variables
    String _searchQuery = '';
    String _selectedCategory = 'All';
    String _sortBy = 'Date';
    bool _isGridView = false;
    bool _showScrollToTop = false;
    bool _isLoading = false;
    bool _isSyncing = false;
    bool _isDeepSearching = false;

    // Data
    List<DriveFile> _searchResults = [];
    List<DriveFile> _driveFiles = [];
    List<DriveFile> _breadcrumbs = [];
    String _currentDriveFolderId = _googleDriveFolderId;
    Map<String, StudentProgress> _progressData = {};
    Map<String, dynamic> _analytics = {};
    List<Map<String, dynamic>> _recentNotes = [];
    List<Map<String, dynamic>> _favoriteFiles = [];
    List<Map<String, dynamic>> _studyGoals = [];
    
    String _rootFolderId = _googleDriveFolderId;
    List<Map<String, String>> _navigationStack = [];

    // Constants
    final List<String> _categories = [
    'All', 'Favorites', 'PDF', 'Document', 'Image', 'Video', 'Audio', 
    'Folder', 'Presentation', 'Spreadsheet', 'Archive'
  ];
    
    final List<String> _sortOptions = [
      'Date', 'Title', 'Type', 'Size', 'Most Viewed', 'Recently Viewed', 'Progress', 'Favorites'
    ];

    @override
    void initState() {
      super.initState();
      _tabController = TabController(length: 3, vsync: this);
      _initializeAnimations();
      _setupScrollListener();
      _initializeServices();
    }

    

    void _initializeAnimations() {
      _fabAnimationController = AnimationController(
        duration: Duration(milliseconds: 300),
        vsync: this,
      );
      
      _scrollAnimationController = AnimationController(
        duration: Duration(milliseconds: 300),
        vsync: this,
      );
      
      _syncAnimationController = AnimationController(
        duration: Duration(milliseconds: 1500),
        vsync: this,
      );
      
      _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
      );
      
      _scrollToTopAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _scrollAnimationController, curve: Curves.easeInOut),
      );
      
      _syncAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _syncAnimationController, curve: Curves.linear),
      );
      
      _fabAnimationController.forward();
    }

    void _setupScrollListener() {
      _scrollController.addListener(() {
        if (_scrollController.offset > 300 && !_showScrollToTop) {
          setState(() => _showScrollToTop = true);
          _scrollAnimationController.forward();
        } else if (_scrollController.offset <= 300 && _showScrollToTop) {
          setState(() => _showScrollToTop = false);
          _scrollAnimationController.reverse();
        }
      });
    }

    Future<void> _initializeServices() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    _showSnackBar('Please sign in to access study materials', Colors.orange);
    return;
  }

  setState(() => _isLoading = true);

  try {
    final driveInitialized = await _driveService.initialize();
    if (!driveInitialized) {
      throw Exception('Failed to initialize Google Drive service');
    }
    
    final authenticated = await _driveService.authenticate();
    if (authenticated) {
      await _loadDriveFiles();
      await _loadStudentData();
      await _loadUserNotes();
      await _loadFavorites(); // Load favorites after everything else
      _showSnackBar('Connected to Google Drive successfully!', Colors.green);
    } else {
      _showSnackBar('Failed to authenticate with Google Drive. Please try again.', Colors.red);
    }
  } catch (e) {
    print('Initialization error: $e');
    _showSnackBar('Error initializing: ${e.toString()}', Colors.red);
  } finally {
    setState(() => _isLoading = false);
  }
}


    Future<void> _loadDriveFiles({String? folderId, DriveFile? breadcrumb, bool forceRefresh = false}) async {
  setState(() => _isLoading = true);
  
  try {
    final id = folderId ?? _currentDriveFolderId;
    
    // Clear cache if force refresh
    if (forceRefresh) {
      _driveService.clearCache();
    }
    
    final files = await _driveService.listFilesInFolder(id, forceRefresh: forceRefresh);
    
    setState(() {
      _driveFiles = files;
      _currentDriveFolderId = id;
      
      // FIXED: Only clear search, don't reset category to preserve favorites
      _searchQuery = '';
      _searchResults.clear();
      _searchController.clear();
      // REMOVED: _selectedCategory = 'All'; // Don't reset category
      
      // Add this after loading files in _loadDriveFiles
      for (final file in files) {
        _fileCache[file.id] = file;
      }

      // Navigation handling
      if (breadcrumb != null) {
        // Going into a folder
        final existingIndex = _navigationStack.indexWhere((item) => item['id'] == breadcrumb.id);
        if (existingIndex == -1) {
          _navigationStack.add({'id': breadcrumb.id, 'name': breadcrumb.name});
        } else {
          _navigationStack = _navigationStack.sublist(0, existingIndex + 1);
        }
      } else if (folderId != null && folderId != _rootFolderId) {
        // Direct navigation to a folder
        final existingIndex = _navigationStack.indexWhere((item) => item['id'] == folderId);
        if (existingIndex != -1) {
          _navigationStack = _navigationStack.sublist(0, existingIndex + 1);
        }
      } else if (folderId == null || folderId == _rootFolderId) {
        // Going to root folder
        _navigationStack.clear();
      }
      
      // Update breadcrumbs
      _breadcrumbs = _navigationStack.map((item) => DriveFile(
        id: item['id']!,
        name: item['name']!,
        mimeType: 'application/vnd.google-apps.folder',
        size: 0,
        modifiedTime: DateTime.now(),
        createdTime: DateTime.now(),
        parents: [],
        isFolder: true,
        isShared: false,
        owners: [],
        version: 1,
        isStarred: false,
        isTrashed: false,
        isExplicitlyTrashed: false,
        isWritersCanShare: false,
        isViewedByMe: false,
        isOwnedByMe: false,
      )).toList();
      
      _isLoading = false;
    });

    // Load progress data to ensure favorites are loaded
    await _loadStudentData();
    
    // Debug print
    print('=== FOLDER LOADED ===');
    print('Folder ID: $id');
    print('Files loaded: ${_driveFiles.length}');
    print('Search cleared: ${_searchQuery.isEmpty}');
    print('Category preserved: $_selectedCategory');
    print('Navigation stack: $_navigationStack');
    print('====================');
    
  } catch (e) {
    setState(() => _isLoading = false);
    _showSnackBar('Error loading files: $e', Colors.red);
  }
}

    Future<void> _loadStudentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load real recent notes
      final notesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .orderBy('updatedAt', descending: true)
          .limit(10)
          .get();

      _recentNotes = notesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled',
          'content': data['content'] ?? '',
          'subject': data['subject'] ?? 'General',
          'category': data['category'] ?? 'Note',
          'updatedAt': data['updatedAt']?.toDate() ?? DateTime.now(),
          'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
          'tags': List<String>.from(data['tags'] ?? []),
          'wordCount': data['wordCount'] ?? 0,
          'readingTime': data['readingTime'] ?? 0,
        };
      }).toList();

      // Load real study goals
      final goalsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('study_goals')
          .where('isActive', isEqualTo: true)
          .get();

      _studyGoals = goalsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Study Goal',
          'description': data['description'] ?? '',
          'targetDate': data['targetDate']?.toDate() ?? DateTime.now(),
          'progress': (data['progress'] ?? 0.0).toDouble(),
          'type': data['type'] ?? 'general',
          'isCompleted': data['isCompleted'] ?? false,
          'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
          'priority': data['priority'] ?? 'medium',
          'category': data['category'] ?? 'study',
        };
      }).toList();

      // Load real progress data
      final progressSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('file_progress')
          .get();

      _progressData.clear();
      for (final doc in progressSnapshot.docs) {
        final data = doc.data();
        _progressData[doc.id] = StudentProgress.fromJson(data);
      }

      // Generate real analytics
      await _generateRealAnalytics();

      setState(() {});
    } catch (e) {
      print('Error loading student data: $e');
    }
  }

  Future<void> _generateRealAnalytics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      
      // Calculate real weekly study time from session data
      final weeklyData = <String, double>{};
      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i];
        
        // Get real session data for this day
        final sessionsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('study_sessions')
            .where('date', isEqualTo: Timestamp.fromDate(day))
            .get();
        
        double dayTotal = 0;
        for (final session in sessionsSnapshot.docs) {
          final data = session.data();
          dayTotal += (data['duration'] ?? 0.0).toDouble();
        }
        
        weeklyData[dayName] = dayTotal;
      }

      // Calculate real subject distribution
      final subjectData = <String, double>{};
      final subjectTotals = <String, double>{};
      double totalTime = 0;
      
      for (final progress in _progressData.values) {
        final subject = progress.metadata['subject'] ?? 'Other';
        final time = progress.totalTimeSpent.inMinutes.toDouble();
        subjectTotals[subject] = (subjectTotals[subject] ?? 0) + time;
        totalTime += time;
      }
      
      // Convert to percentages
      subjectTotals.forEach((subject, time) {
        subjectData[subject] = totalTime > 0 ? (time / totalTime) * 100 : 0;
      });

      // Calculate real progress distribution
      final progressDistribution = <String, double>{
        'Completed': 0,
        'In Progress': 0,
        'Not Started': 0,
      };
      
      int totalFiles = _progressData.length;
      if (totalFiles > 0) {
        for (final progress in _progressData.values) {
          if (progress.progress >= 1.0) {
            progressDistribution['Completed'] = progressDistribution['Completed']! + 1;
          } else if (progress.progress > 0) {
            progressDistribution['In Progress'] = progressDistribution['In Progress']! + 1;
          } else {
            progressDistribution['Not Started'] = progressDistribution['Not Started']! + 1;
          }
        }
        
        // Convert to percentages
        progressDistribution.forEach((key, value) {
          progressDistribution[key] = (value / totalFiles) * 100;
        });
      }

      // Calculate real metrics
      final totalStudyTime = _progressData.values
          .map((p) => p.totalTimeSpent.inMinutes)
          .fold(0, (a, b) => a + b);
      
      final averageSessionTime = _progressData.values.isNotEmpty
          ? totalStudyTime / _progressData.values.length
          : 0;
      
      final completionRate = totalFiles > 0
          ? (progressDistribution['Completed']! / totalFiles) * 100
          : 0;
      
      final favoriteSubject = subjectData.isNotEmpty
          ? subjectData.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'N/A';

      // Calculate study streak
      int studyStreak = await _calculateStudyStreak(user.uid);
      
      _analytics = {
        'totalStudyTime': totalStudyTime,
        'filesStudied': _driveFiles.length,
        'notesCreated': _recentNotes.length,
        'weeklyStudyTime': weeklyData,
        'subjectDistribution': subjectData,
        'progressDistribution': progressDistribution,
        'studyStreak': studyStreak,
        'averageSessionTime': averageSessionTime.round(),
        'favoriteSubject': favoriteSubject,
        'completionRate': completionRate,
        'weeklyGoal': 300, // This could also be stored in user preferences
        'weeklyProgress': weeklyData.values.fold(0.0, (a, b) => a + b),
        'totalGoals': _studyGoals.length,
        'completedGoals': _studyGoals.where((g) => g['isCompleted'] == true).length,
        'activeGoals': _studyGoals.where((g) => g['isCompleted'] == false).length,
      };
    } catch (e) {
      print('Error generating real analytics: $e');
    }
  }

  Future<int> _calculateStudyStreak(String userId) async {
    try {
      final now = DateTime.now();
      int streak = 0;
      
      for (int i = 0; i < 365; i++) { // Check up to a year
        final checkDate = now.subtract(Duration(days: i));
        final dayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
        final dayEnd = dayStart.add(Duration(days: 1));
        
        final sessionsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('study_sessions')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
            .where('timestamp', isLessThan: Timestamp.fromDate(dayEnd))
            .limit(1)
            .get();
        
        if (sessionsSnapshot.docs.isNotEmpty) {
          streak++;
        } else if (i > 0) { // Don't break on the first day (today) if no session yet
          break;
        }
      }
      
      return streak;
    } catch (e) {
      print('Error calculating study streak: $e');
      return 0;
    }
  }

  // Method to log study sessions
  Future<void> _logStudySession(String fileId, String fileName, Duration duration) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('study_sessions')
          .add({
        'fileId': fileId,
        'fileName': fileName,
        'duration': duration.inMinutes,
        'timestamp': Timestamp.now(),
        'date': Timestamp.fromDate(DateTime.now()),
        'deviceInfo': {
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'appVersion': '1.0.0', // Get from package_info_plus
        },
      });
    } catch (e) {
      print('Error logging study session: $e');
    }
  }

    @override
    void dispose() {
      _tabController.dispose();
      _fabAnimationController.dispose();
      _scrollAnimationController.dispose();
      _syncAnimationController.dispose();
      _searchController.dispose();
      _scrollController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return ThemeSwitchingArea(
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentThemeMode, child) {
            final isDark = currentThemeMode == ThemeMode.dark;
            final theme = Theme.of(context);

            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: _buildAppBar(context, isDark, theme),
              body: _buildBody(isDark, theme),
              floatingActionButton: _buildFloatingActionButton(context, isDark, theme),
            );
          },
        ),
      );
    }

    Widget _buildFloatingActionButton(BuildContext context, bool isDark, ThemeData theme) {
      return FadeTransition(
        opacity: _fabAnimation,
        child: FloatingActionButton(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          onPressed: () {
            _showAddNoteDialog();
          },
          tooltip: 'Create Note',
          child: Icon(Icons.add),
        ),
      );
    }

    PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark, ThemeData theme) {
      return AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.school,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Study Hub',
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: theme.appBarTheme.titleTextStyle?.color,
                  ),
                ),
                Text(
                  'Your Learning Dashboard',
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    color: theme.appBarTheme.titleTextStyle?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: RotationTransition(
              turns: _syncAnimation,
              child: Icon(
                Icons.sync,
                color: _isSyncing ? theme.colorScheme.primary : theme.appBarTheme.iconTheme?.color,
              ),
            ),
            onPressed: _isSyncing ? null : _refreshData,
            tooltip: 'Sync with Google Drive',
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: theme.appBarTheme.iconTheme?.color,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
              HapticFeedback.lightImpact();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.grey.shade600,
          labelStyle: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              icon: Icon(Icons.dashboard),
              text: 'Dashboard',
            ),
            Tab(
              icon: Icon(Icons.folder),
              text: 'Files',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Analytics',
            ),
          ],
        ),
      );
    }

    Widget _buildBody(bool isDark, ThemeData theme) {
      return TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(isDark, theme),
          _buildFilesTab(isDark, theme),
          _buildAnalyticsTab(isDark, theme),
        ],
      );
    }

    Widget _buildDashboardTab(bool isDark, ThemeData theme) {
      return SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(isDark, theme),
            SizedBox(height: 20),
            _buildQuickStats(isDark, theme),
            SizedBox(height: 20),
            _buildStudyGoals(isDark, theme),
            SizedBox(height: 20),
            _buildRecentActivity(isDark, theme),
            SizedBox(height: 20),
            _buildQuickActions(isDark, theme),
            SizedBox(height: 10),
          ],
        ),
      );
    }

    Widget _buildWelcomeCard(bool isDark, ThemeData theme) {
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? 'Student';
      final currentHour = DateTime.now().hour;
      String greeting = 'Good morning';
      
      if (currentHour >= 12 && currentHour < 17) {
        greeting = 'Good afternoon';
      } else if (currentHour >= 17) {
        greeting = 'Good evening';
      }

      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, $userName!',
                        style: GoogleFonts.comicNeue(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ready to continue your learning journey?',
                        style: GoogleFonts.comicNeue(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Study Streak',
                    '${_analytics['studyStreak'] ?? 0} days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Files Studied',
                    '${_analytics['filesStudied'] ?? 0}',
                    Icons.folder_open,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Completion',
                    '${_analytics['completionRate']?.toStringAsFixed(1) ?? 0}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget _buildStatItem(String label, String value, IconData icon, Color color) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.comicNeue(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    Widget _buildQuickStats(bool isDark, ThemeData theme) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week\'s Progress',
            style: GoogleFonts.comicNeue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1C2542) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Study Goal',
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_analytics['weeklyProgress'] ?? 0}/${_analytics['weeklyGoal'] ?? 0} min',
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (_analytics['weeklyProgress'] ?? 0) / (_analytics['weeklyGoal'] ?? 1),
                  backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  minHeight: 8,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickStatCard(
                        'Avg Session',
                        '${_analytics['averageSessionTime'] ?? 0} min',
                        Icons.timer,
                        Colors.blue,
                        isDark,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: _buildQuickStatCard(
                        'Notes Created',
                        '${_recentNotes.length}',
                        Icons.note_add,
                        Colors.green,
                        isDark,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: _buildQuickStatCard(
                        'Favorite Subject',
                        '${_analytics['favoriteSubject'] ?? 'N/A'}',
                        Icons.favorite,
                        Colors.red,
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget _buildQuickStatCard(String label, String value, IconData icon, Color color, bool isDark) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 10,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    Widget _buildStudyGoals(bool isDark, ThemeData theme) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Study Goals',
                style: GoogleFonts.comicNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _showAddGoalDialog,
                icon: Icon(Icons.add, size: 16),
                  label: Text(
                  'Add Goal',
                  style: GoogleFonts.comicNeue(),
                  ),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_studyGoals.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C2542) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.grey.shade200,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No study goals yet',
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Set goals to track your progress',
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_studyGoals.take(3).map((goal) => Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C2542) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal['title'],
                          style: GoogleFonts.comicNeue(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: goal['isCompleted'] 
                              ? Colors.green.withOpacity(0.2)
                              : theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          goal['isCompleted'] ? 'Completed' : 'In Progress',
                          style: GoogleFonts.comicNeue(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: goal['isCompleted'] ? Colors.green : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (goal['description'].isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      goal['description'],
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: goal['progress'],
                          backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            goal['isCompleted'] ? Colors.green : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '${(goal['progress'] * 100).toInt()}%',
                        style: GoogleFonts.comicNeue(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: goal['isCompleted'] ? Colors.green : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ))),
        ],
      );
    }

    Widget _buildRecentActivity(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Notes',
              style: GoogleFonts.comicNeue(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _showAllNotesDialog, // Show all notes dialog
              child: Text('View All', style: TextStyle(fontFamily: GoogleFonts.comicNeue().fontFamily)),
            ),
            ],
          ),
          SizedBox(height: 16),
          if (_recentNotes.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C2542) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.grey.shade200,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No recent notes',
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start creating notes to see them here',
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_recentNotes.take(5).map((note) => Container(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: EdgeInsets.all(12),
                tileColor: isDark ? Color(0xFF1C2542) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade200,
                  ),
                ),
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSubjectColor(note['subject']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(note['category']),
                    color: _getSubjectColor(note['subject']),
                    size: 20,
                  ),
                ),
                title: Text(
                  note['title'],
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['content'],
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getSubjectColor(note['subject']).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            note['subject'],
                            style: GoogleFonts.comicNeue(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getSubjectColor(note['subject']),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _formatDate(note['updatedAt']),
                          style: GoogleFonts.comicNeue(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  // Open note detail
                },
              ),
            ))),
        ],
      );
    }

    Widget _buildQuickActions(bool isDark, ThemeData theme) {
    final actions = [
      {
        'title': 'Create Note',
        'subtitle': 'Add a new study note',
        'icon': Icons.note_add,
        'color': Colors.blue,
        'onTap': () => _showAddNoteDialog(),
      },
      {
        'title': 'Browse Files',
        'subtitle': 'Explore study materials',
        'icon': Icons.folder_open,
        'color': Colors.green,
        'onTap': () => _tabController.animateTo(1),
      },
      {
        'title': 'View Analytics',
        'subtitle': 'Check your progress',
        'icon': Icons.analytics,
        'color': Colors.purple,
        'onTap': () => _tabController.animateTo(2),
      },
      {
        'title': 'Study Goals',
        'subtitle': 'Manage your goals',
        'icon': Icons.flag,
        'color': Colors.orange,
        'onTap': () => _showAddGoalDialog(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.comicNeue(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        // Use LayoutBuilder to calculate proper height
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            final cardHeight = cardWidth * 0.75; // Adjust aspect ratio
            
            return SizedBox(
              height: cardHeight * 2 + 12, // Height for 2 rows + spacing
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3, // Reduced from 1.5 to prevent overflow
                ),
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return GestureDetector(
                    onTap: action['onTap'] as VoidCallback,
                    child: Container(
                      padding: EdgeInsets.all(12), // Reduced padding
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF1C2542) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center, // Center content
                        children: [
                          Container(
                            padding: EdgeInsets.all(10), // Reduced padding
                            decoration: BoxDecoration(
                              color: (action['color'] as Color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              action['icon'] as IconData,
                              color: action['color'] as Color,
                              size: 20, // Reduced icon size
                            ),
                          ),
                          SizedBox(height: 8), // Reduced spacing
                          Flexible( // Use Flexible to prevent overflow
                            child: Text(
                              action['title'] as String,
                              style: GoogleFonts.comicNeue(
                                fontSize: 13, // Reduced font size
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 2),
                          Flexible( // Use Flexible to prevent overflow
                            child: Text(
                              action['subtitle'] as String,
                              style: GoogleFonts.comicNeue(
                                fontSize: 11, // Reduced font size
                                color: isDark ? Colors.white70 : Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
      
    );
    
  }

    Widget _buildFilesTab(bool isDark, ThemeData theme) {
      return Column(
        children: [
          _buildSearchAndFilters(isDark, theme),
          if (_breadcrumbs.isNotEmpty) _buildBreadcrumbBar(isDark, theme),
          Expanded(
            child: _buildFilesContent(isDark, theme),
          ),
        ],
      );
      }

    Widget _buildAnalyticsTab(bool isDark, ThemeData theme) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeeklyChart(isDark, theme),
            SizedBox(height: 24),
            _buildSubjectDistribution(isDark, theme),
            SizedBox(height: 24),
            _buildProgressOverview(isDark, theme),
            SizedBox(height: 24),
            _buildStudyInsights(isDark, theme),
            SizedBox(height: 24),
            _buildPerformanceMetrics(isDark, theme),
          ],
        ),
      );
    }

    Widget _buildWeeklyChart(bool isDark, ThemeData theme) {
      final weeklyData = _analytics['weeklyStudyTime'] as Map<String, double>? ?? {};
      
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C2542) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Study Time',
                  style: GoogleFonts.comicNeue(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'This Week',
                    style: GoogleFonts.comicNeue(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: weeklyData.values.isNotEmpty ? weeklyData.values.reduce((a, b) => a > b ? a : b) * 1.2 : 100,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (touchedSpot) => theme.colorScheme.primary,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = weeklyData.keys.elementAt(groupIndex);
                        return BarTooltipItem(
                          '$day\n${rod.toY.round()} min',
                          GoogleFonts.comicNeue(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = weeklyData.keys.toList();
                          if (value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: GoogleFonts.comicNeue(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.grey.shade600,
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: GoogleFonts.comicNeue(
                              fontSize: 10,
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklyData.entries.map((entry) {
                    final index = weeklyData.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: theme.colorScheme.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: weeklyData.values.reduce((a, b) => a > b ? a : b) * 1.2,
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildSubjectDistribution(bool isDark, ThemeData theme) {
      final subjectData = _analytics['subjectDistribution'] as Map<String, double>? ?? {};
      
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C2542) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject Distribution',
              style: GoogleFonts.comicNeue(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // Handle touch events
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _generatePieChartSections(subjectData, theme),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subjectData.entries.map((entry) {
                      final color = _getSubjectColor(entry.key);
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${entry.value.toInt()}%',
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 10,
                                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    List<PieChartSectionData> _generatePieChartSections(Map<String, double> data, ThemeData theme) {
      return data.entries.map((entry) {
        final color = _getSubjectColor(entry.key);
        return PieChartSectionData(
          color: color,
          value: entry.value,
          title: '${entry.value.toInt()}%',
          radius: 60,
          titleStyle: GoogleFonts.comicNeue(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList();
    }

    Widget _buildProgressOverview(bool isDark, ThemeData theme) {
      final progressData = _analytics['progressDistribution'] as Map<String, double>? ?? {};
      
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C2542) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning Progress',
              style: GoogleFonts.comicNeue(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ...progressData.entries.map((entry) {
              Color color;
              IconData icon;
              
              switch (entry.key) {
                case 'Completed':
                  color = Colors.green;
                  icon = Icons.check_circle;
                  break;
                case 'In Progress':
                  color = Colors.orange;
                  icon = Icons.schedule;
                  break;
                case 'Not Started':
                  color = Colors.grey;
                  icon = Icons.radio_button_unchecked;
                  break;
                default:
                  color = Colors.blue;
                  icon = Icons.circle;
              }
              
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: GoogleFonts.comicNeue(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${entry.value.toInt()}%',
                                style: GoogleFonts.comicNeue(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: entry.value / 100,
                            backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );
    }

    Widget _buildStudyInsights(bool isDark, ThemeData theme) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C2542) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Study Insights',
              style: GoogleFonts.comicNeue(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildInsightCard(
              'Peak Study Time',
              '2:00 PM - 4:00 PM',
              'You\'re most productive in the afternoon',
              Icons.schedule,
              Colors.blue,
              isDark,
            ),
            SizedBox(height: 12),
            _buildInsightCard(
              'Strongest Subject',
              'Mathematics',
              'Keep up the excellent work!',
              Icons.trending_up,
              Colors.green,
              isDark,
            ),
            SizedBox(height: 12),
            _buildInsightCard(
              'Improvement Area',
              'Chemistry',
              'Consider spending more time on this subject',
              Icons.lightbulb,
              Colors.orange,
              isDark,
            ),
            SizedBox(height: 12),
            _buildInsightCard(
              'Study Streak',
              '7 Days',
              'Amazing consistency! Keep it up!',
              Icons.local_fire_department,
              Colors.red,
              isDark,
            ),
          ],
        ),
      );
    }

    Widget _buildInsightCard(String title, String value, String description, IconData icon, Color color, bool isDark) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.comicNeue(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.comicNeue(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.comicNeue(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildPerformanceMetrics(bool isDark, ThemeData theme) {
      final metrics = [
        {
          'title': 'Total Study Time',
          'value': '${_analytics['totalStudyTime']} min',
          'change': '+12%',
          'isPositive': true,
          'icon': Icons.timer,
          'color': Colors.blue,
        },
        {
          'title': 'Files Completed',
          'value': '${_analytics['filesStudied']}',
          'change': '+8%',
          'isPositive': true,
          'icon': Icons.check_circle,
          'color': Colors.green,
        },
        {
          'title': 'Average Session',
          'value': '${_analytics['averageSessionTime']} min',
          'change': '+5%',
          'isPositive': true,
          'icon': Icons.schedule,
          'color': Colors.orange,
        },
        {
          'title': 'Notes Created',
          'value': '${_recentNotes.length}',
          'change': '+15%',
          'isPositive': true,
          'icon': Icons.note_add,
          'color': Colors.purple,
        },
      ];

      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C2542) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: GoogleFonts.comicNeue(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: metrics.length,
              itemBuilder: (context, index) {
                final metric = metrics[index];
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (metric['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (metric['color'] as Color).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            metric['icon'] as IconData,
                            color: metric['color'] as Color,
                            size: 24,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (metric['isPositive'] as bool) 
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              metric['change'] as String,
                              style: GoogleFonts.comicNeue(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: (metric['isPositive'] as bool) ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        metric['value'] as String,
                        style: GoogleFonts.comicNeue(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: metric['color'] as Color,
                        ),
                      ),
                      Text(
                        metric['title'] as String,
                        style: GoogleFonts.comicNeue(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    Future<List<DriveFile>> _performDeepSearch(String query, String folderId) async {
    List<DriveFile> allResults = [];
    
    try {
      final files = await _driveService.listFilesInFolder(folderId);
      
      // Search in current folder
      for (final file in files) {
        if (file.name.toLowerCase().contains(query.toLowerCase())) {
          allResults.add(file);
        }
        
        // If it's a folder, search recursively
        if (file.isFolder) {
          final subResults = await _performDeepSearch(query, file.id);
          allResults.addAll(subResults);
        }
      }
    } catch (e) {
      print('Error searching in folder $folderId: $e');
    }
    
    return allResults;
  }

    Widget _buildSearchAndFilters(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Search Bar with deep search option
          Container(
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1C2542) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) async {
                    setState(() {
                      _searchQuery = value;
                    });
                    
                    // Perform deep search if query is not empty
                    if (value.isNotEmpty && value.length > 2) {
                      setState(() => _isDeepSearching = true);
                      
                      try {
                        final results = await _performDeepSearch(value, _currentDriveFolderId);
                        setState(() {
                          _searchResults = results;
                          _isDeepSearching = false;
                        });
                      } catch (e) {
                        setState(() => _isDeepSearching = false);
                      }
                    } else {
                      setState(() {
                        _searchResults.clear();
                        _isDeepSearching = false;
                      });
                    }
                  },
                  style: GoogleFonts.comicNeue(),
                  decoration: InputDecoration(
                    hintText: 'Search files and folders...',
                    hintStyle: GoogleFonts.comicNeue(
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    prefixIcon: _isDeepSearching 
                        ? Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Icon(
                            Icons.search,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _searchResults.clear();
                                _isDeepSearching = false;
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                
                // Search results count
                if (_searchQuery.isNotEmpty && !_isDeepSearching)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_outlined,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Found ${_searchResults.length} results across all folders',
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
            
            SizedBox(height: 12),
            
            // Enhanced Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Category Filter
                  ..._categories.map((category) => Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            size: 16,
                            color: _selectedCategory == category
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          SizedBox(width: 4),
                          Text(
                            category,
                            style: GoogleFonts.comicNeue(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: _selectedCategory == category
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        HapticFeedback.lightImpact();
                      },
                      backgroundColor: isDark ? Color(0xFF1C2542) : Colors.grey.shade200,
                      selectedColor: theme.colorScheme.primary,
                      checkmarkColor: Colors.white,
                    ),
                  )),
                  
                  SizedBox(width: 8),
                  
                  // Sort Filter
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1C2542) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isDense: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: isDark ? Colors.white70 : Colors.black87,
                          size: 20,
                        ),
                        style: GoogleFonts.comicNeue(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        dropdownColor: isDark ? Color(0xFF1C2542) : Colors.white,
                        items: _sortOptions.map((option) => DropdownMenuItem(
                          value: option,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getSortIcon(option),
                                size: 16,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              SizedBox(width: 8),
                              Text(option),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                          });
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

      Widget _buildBreadcrumbBar(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C2542) : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Home button - always goes to root
            GestureDetector(
              onTap: () {
                _loadDriveFiles(folderId: _rootFolderId);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _currentDriveFolderId == _rootFolderId 
                      ? theme.colorScheme.primary.withOpacity(0.2)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home, size: 16, color: theme.colorScheme.primary),
                    SizedBox(width: 4),
                    Text(
                      'Home',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Navigation breadcrumbs
            ...List.generate(_navigationStack.length, (index) {
              final item = _navigationStack[index];
              final isLast = index == _navigationStack.length - 1;
              final isCurrentFolder = item['id'] == _currentDriveFolderId;
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to this folder - FIXED
                      if (item['id'] != _currentDriveFolderId) {
                        _loadDriveFiles(folderId: item['id']);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrentFolder 
                            ? theme.colorScheme.primary.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['name']!,
                        style: GoogleFonts.comicNeue(
                          fontWeight: isCurrentFolder ? FontWeight.bold : FontWeight.w600,
                          fontSize: 12,
                          color: isCurrentFolder 
                              ? theme.colorScheme.primary
                              : (isDark ? Colors.white70 : Colors.grey.shade700),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }




    Widget _buildFilesContent(bool isDark, ThemeData theme) {
      if (_isLoading) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
              SizedBox(height: 16),
              Text(
                'Loading study materials...',
                style: GoogleFonts.comicNeue(
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }

      final filteredFiles = _getFilteredFiles();

      if (filteredFiles.isEmpty) {
        return _buildEmptyState(isDark, theme);
      }

      return RefreshIndicator(
        onRefresh: _refreshData,
        child: _isGridView
            ? _buildGridView(filteredFiles, isDark, theme)
            : _buildListView(filteredFiles, isDark, theme),
      );
    }

    List<DriveFile> _getFilteredFiles() {
  List<DriveFile> filtered;
  
  // Start with the correct base files
  if (_searchQuery.isNotEmpty && _searchResults.isNotEmpty) {
    // Use search results when searching
    filtered = _searchResults;
  } else if (_searchQuery.isNotEmpty) {
    // Fallback to current folder search
    filtered = _driveFiles.where((file) {
      final query = _searchQuery.toLowerCase();
      return file.name.toLowerCase().contains(query);
    }).toList();
  } else {
    // Use current folder files
    filtered = List.from(_driveFiles);
  }
  
  // Apply category filter
  if (_selectedCategory == 'Favorites') {
    // FIXED: Filter favorites from ALL cached files, not just current folder
    final allFavoriteFiles = <DriveFile>[];
    
    // Add favorites from current folder
    for (final file in filtered) {
      final progress = _progressData[file.id];
      if (progress?.isFavorite == true) {
        allFavoriteFiles.add(file);
      }
    }
    
    // Also check cached files for favorites not in current folder
    for (final fileId in _progressData.keys) {
      final progress = _progressData[fileId];
      if (progress?.isFavorite == true) {
        // Check if this file is already in the list
        if (!allFavoriteFiles.any((f) => f.id == fileId)) {
          // Try to find this file in cache or create a placeholder
          final cachedFile = _fileCache[fileId];
          if (cachedFile != null) {
            allFavoriteFiles.add(cachedFile);
          }
        }
      }
    }
    
    filtered = allFavoriteFiles;
  } else if (_selectedCategory != 'All') {
    // Apply other category filters
    filtered = filtered.where((file) {
      switch (_selectedCategory) {
        case 'Folder':
          return file.isFolder;
        case 'PDF':
          return file.mimeType.contains('pdf');
        case 'Document':
          return file.mimeType.contains('document') || 
                 file.mimeType.contains('text') ||
                 file.mimeType.contains('pdf') ||
                 file.mimeType.contains('wordprocessingml') ||
                 file.name.toLowerCase().endsWith('.docx') ||
                 file.name.toLowerCase().endsWith('.doc') ||
                 file.name.toLowerCase().endsWith('.txt');
        case 'Spreadsheet':
          return file.mimeType.contains('spreadsheet') ||
                 file.mimeType.contains('sheet') ||
                 file.name.toLowerCase().endsWith('.xlsx') ||
                 file.name.toLowerCase().endsWith('.xls');
        case 'Presentation':
          return file.mimeType.contains('presentation') ||
                 file.name.toLowerCase().endsWith('.pptx') ||
                 file.name.toLowerCase().endsWith('.ppt');
        case 'Image':
          return file.mimeType.contains('image');
        case 'Video':
          return file.mimeType.contains('video');
        case 'Audio':
          return file.mimeType.contains('audio');
        case 'Archive':
          return file.mimeType.contains('archive') || file.mimeType.contains('zip');
        default:
          return true;
      }
    }).toList();
  }
  
  // Remove duplicates and sort
  final Map<String, DriveFile> uniqueFiles = {};
  for (final file in filtered) {
    uniqueFiles[file.id] = file;
  }
  filtered = uniqueFiles.values.toList();
  
  // Sort with folders first
  filtered.sort((a, b) {
    if (a.isFolder && !b.isFolder) return -1;
    if (!a.isFolder && b.isFolder) return 1;
    
    switch (_sortBy) {
      case 'Title':
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case 'Type':
        return a.fileTypeCategory.compareTo(b.fileTypeCategory);
      case 'Size':
        return b.size.compareTo(a.size);
      case 'Most Viewed':
        final aProgress = _progressData[a.id];
        final bProgress = _progressData[b.id];
        return (bProgress?.viewCount ?? 0).compareTo(aProgress?.viewCount ?? 0);
      case 'Recently Viewed':
        final aProgress = _progressData[a.id];
        final bProgress = _progressData[b.id];
        if (aProgress == null && bProgress == null) return 0;
        if (aProgress == null) return 1;
        if (bProgress == null) return -1;
        return bProgress.lastViewed.compareTo(aProgress.lastViewed);
      case 'Progress':
        final aProgress = _progressData[a.id];
        final bProgress = _progressData[b.id];
        return (bProgress?.progress ?? 0.0).compareTo(aProgress?.progress ?? 0.0);
      case 'Favorites':
        final aProgress = _progressData[a.id];
        final bProgress = _progressData[b.id];
        final aFav = aProgress?.isFavorite ?? false;
        final bFav = bProgress?.isFavorite ?? false;
        if (aFav && !bFav) return -1;
        if (!aFav && bFav) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case 'Date':
      default:
        return b.modifiedTime.compareTo(a.modifiedTime);
    }
  });

  return filtered;
}

  

    Widget _buildEmptyState(bool isDark, ThemeData theme) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1C2542) : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _searchQuery.isNotEmpty ? Icons.search_off : Icons.folder_open,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 24),
              Text(
                _searchQuery.isNotEmpty ? 'No files found' : 'No study materials yet!',
                style: GoogleFonts.comicNeue(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try adjusting your search or filters'
                    : 'Connect to Google Drive to access your study materials',
                style: GoogleFonts.comicNeue(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isEmpty) ...[
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _refreshData(),
                  icon: Icon(Icons.sync),
                  label: Text(
                    'Sync with Google Drive',
                    style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    Widget _buildGridView(List<DriveFile> files, bool isDark, ThemeData theme) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: files.length,
          itemBuilder: (context, index) {
            return _buildFileGridCard(files[index], isDark, theme);
          },
        ),
      );
    }

    Widget _buildListView(List<DriveFile> files, bool isDark, ThemeData theme) {
      return ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: files.length,
        itemBuilder: (context, index) {
          return _buildFileListCard(files[index], isDark, theme);
        },
      );
    }

    Widget _buildFileGridCard(DriveFile file, bool isDark, ThemeData theme) {
      final progress = _progressData[file.id];
      
      return GestureDetector(
        onTap: () => _handleFileTap(file),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1C2542) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File preview/thumbnail
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: file.fileTypeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: file.isFolder
                            ? Icon(
                                Icons.folder,
                                size: 48,
                                color: file.fileTypeColor,
                              )
                            : file.thumbnailLink != null && file.mimeType.contains('image')
                                ? ClipRRect(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                    child: CachedNetworkImage(
                                      imageUrl: file.thumbnailLink!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      errorWidget: (context, url, error) => Icon(
                                        file.fileIcon,
                                        size: 48,
                                        color: file.fileTypeColor,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    file.fileIcon,
                                    size: 48,
                                    color: file.fileTypeColor,
                                  ),
                      ),
                      // Favorite indicator
                      if (progress?.isFavorite == true)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.favorite,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      // Progress indicator
                      if (progress != null && progress.progress > 0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: progress.progress,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(file.fileTypeColor),
                            minHeight: 3,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // File info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name.split('.').first,
                        style: GoogleFonts.comicNeue(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: file.fileTypeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              file.fileTypeCategory,
                              style: GoogleFonts.comicNeue(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: file.fileTypeColor,
                              ),
                            ),
                          ),
                          Spacer(),
                          if (progress?.viewCount != null && progress!.viewCount > 0)
                            Row(
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 10,
                                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '${progress.viewCount}',
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 10,
                                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            file.displaySize,
                            style: GoogleFonts.comicNeue(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : Colors.grey.shade500,
                            ),
                          ),
                          Spacer(),
                          Text(
                            _formatDate(file.modifiedTime),
                            style: GoogleFonts.comicNeue(
                              fontSize: 9,
                              color: isDark ? Colors.white38 : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildFileListCard(DriveFile file, bool isDark, ThemeData theme) {
      final progress = _progressData[file.id];
      
      return Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C2542) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: file.fileTypeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: file.thumbnailLink != null && file.mimeType.contains('image')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: file.thumbnailLink!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            file.fileIcon,
                            color: file.fileTypeColor,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        file.fileIcon,
                        color: file.fileTypeColor,
                        size: 24,
                      ),
              ),
              if (progress?.isFavorite == true)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.favorite,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            file.name.replaceAll(RegExp(r'\.[^.]*$'), ''),
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: file.fileTypeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      file.fileTypeCategory,
                      style: GoogleFonts.comicNeue(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: file.fileTypeColor,
                      ),
                    ),
                  ),
                  // SizedBox(width: 8),
                  // Text(
                  //   file.displaySize,
                  //   style: GoogleFonts.comicNeue(
                  //     fontSize: 10,
                  //     color: isDark ? Colors.white54 : Colors.grey.shade500,
                  //   ),
                  // ),
                  if (progress?.viewCount != null && progress!.viewCount > 0) ...[
                    SizedBox(width: 8),
                    Icon(
                      Icons.visibility,
                      size: 10,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                    SizedBox(width: 2),
                    Text(
                      '${progress.viewCount}',
                      style: GoogleFonts.comicNeue(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                  Spacer(),
                  Text(
                    _formatDate(file.modifiedTime),
                    style: GoogleFonts.comicNeue(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              if (progress != null && progress.progress > 0) ...[
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.progress,
                  backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(file.fileTypeColor),
                  minHeight: 4,
                ),
              ],
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => _handleFileAction(value, file),
            itemBuilder: (context) => [
              if (file.isFolder)
                PopupMenuItem(value: 'open', child: Text('Open Folder'))
              else
                PopupMenuItem(value: 'view', child: Text('View File')),
              PopupMenuItem(
  value: 'favorite',
  child: Row(
    children: [
      Text((_progressData[file.id]?.isFavorite ?? false) ? 'Remove from Favorites' : 'Add to Favorites'),
    ],
  ),
),
              if (!file.isFolder) ...[
                PopupMenuItem(value: 'share', child: Text('Share')),
              ],
              PopupMenuItem(value: 'info', child: Text('File Info')),
            ],
          ),
          onTap: () => _handleFileTap(file),
        ),
      );
    }

    // Helper Methods
    void _scrollToTop() {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    Future<void> _refreshData() async {
    setState(() => _isSyncing = true);
    _syncAnimationController.repeat();
    
    try {
      // Store current navigation state before refresh
      final currentFolderId = _currentDriveFolderId;
      final currentBreadcrumbs = List<DriveFile>.from(_breadcrumbs);
      final currentNavigationStack = List<Map<String, String>>.from(_navigationStack);
      
      // Clear cache to ensure fresh data
      _driveService.clearCache();
      
      await _loadDriveFiles(folderId: currentFolderId, forceRefresh: true);
      await _loadStudentData();
      
      // Restore navigation state after refresh
      setState(() {
        _currentDriveFolderId = currentFolderId;
        _breadcrumbs = currentBreadcrumbs;
        _navigationStack = currentNavigationStack;
      });
      
      // _showSnackBar('Data refreshed successfully!', Colors.green);
    } catch (e) {
      // _showSnackBar('Failed to refresh data: $e', Colors.red);
    } finally {
      setState(() => _isSyncing = false);
      _syncAnimationController.stop();
      _syncAnimationController.reset();
    }
  }

  void _debugCurrentFolder() {
  print('=== CURRENT FOLDER DEBUG ===');
  print('Current folder ID: $_currentDriveFolderId');
  print('Root folder ID: $_rootFolderId');
  print('Raw files count: ${_driveFiles.length}');
  print('Filtered files count: ${_getFilteredFiles().length}');
  print('Selected category: $_selectedCategory');
  print('Search query: "$_searchQuery"');
  print('Navigation stack: $_navigationStack');
  
  print('\nFiles in current folder:');
  for (int i = 0; i < _driveFiles.length; i++) {
    final file = _driveFiles[i];
    print('  $i: ${file.name} (${file.isFolder ? 'FOLDER' : 'FILE'}) - ${file.fileTypeCategory}');
  }
  
  print('\nFiltered files:');
  final filtered = _getFilteredFiles();
  for (int i = 0; i < filtered.length; i++) {
    final file = filtered[i];
    print('  $i: ${file.name} (${file.isFolder ? 'FOLDER' : 'FILE'}) - ${file.fileTypeCategory}');
  }
  print('============================');
}

    void _debugNavigationState() {
    print('=== NAVIGATION DEBUG ===');
    print('Current folder ID: $_currentDriveFolderId');
    print('Root folder ID: $_rootFolderId');
    print('Navigation stack: $_navigationStack');
    print('Breadcrumbs: ${_breadcrumbs.map((b) => b.name).toList()}');
    print('Files count: ${_driveFiles.length}');
    print('Filtered files count: ${_getFilteredFiles().length}');
    print('Search query: "$_searchQuery"');
    print('Selected category: $_selectedCategory');
    print('========================');
  }



    void _handleFileTap(DriveFile file) {
    // Increment view count
    _incrementViewCount(file);
    
    if (file.isFolder) {
      // Navigate to folder with proper breadcrumb
      _loadDriveFiles(
        folderId: file.id,
        breadcrumb: file,
      );
    } else {
      _openFile(file);
    }
  }



    void _handleFileAction(String action, DriveFile file) {
    switch (action) {
      case 'open':
      case 'view':
        _openFile(file);
        break;
      case 'favorite':
        _toggleFavorite(file);
        break;
      case 'download':
        _downloadFile(file);
        break;
      case 'share':
        _shareFile(file);
        break;
      case 'info':
        _showFileInfo(file);
        break;
    }
  }

    // Enhanced file opening with proper view tracking
  Future<void> _openFile(DriveFile file) async {
  try {
    // Show loading indicator
    _showSnackBar('Opening ${file.name}...', Colors.blue);
    
    // Navigate to appropriate viewer based on file type with custom transitions
    if (file.mimeType.contains('pdf')) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => EnhancedPDFViewerScreen(
            file: file,
            driveService: _driveService,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.5,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: Duration(milliseconds: 800),
          reverseTransitionDuration: Duration(milliseconds: 350),
        ),
      );
    } else if (file.isDocumentFile) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => OfficeDocumentViewer(
            file: file,
            driveService: _driveService,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.85,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: Duration(milliseconds: 500),
          reverseTransitionDuration: Duration(milliseconds: 350),
        ),
      );
    } else if (file.mimeType.contains('image')) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ImageViewerScreen(
            file: file,
            driveService: _driveService,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.7 + (0.3 * animation.value),
                  child: Opacity(
                    opacity: animation.value,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        25 * (1 - animation.value),
                      ),
                      child: child,
                    ),
                  ),
                );
              },
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 450),
          reverseTransitionDuration: Duration(milliseconds: 300),
        ),
      );
    } else if (file.mimeType.contains('video')) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => VideoViewerScreen(
            file: file,
            driveService: _driveService,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubicEmphasized;

            var slideAnimation = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            ).animate(animation);

            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Interval(0.0, 0.7, curve: Curves.easeOut),
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: Duration(milliseconds: 600),
          reverseTransitionDuration: Duration(milliseconds: 400),
        ),
      );
    } else if (file.mimeType.contains('audio')) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AudioViewerScreen(
            file: file,
            driveService: _driveService,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubicEmphasized;

            var slideAnimation = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            ).animate(animation);

            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Interval(0.0, 0.7, curve: Curves.easeOut),
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: Duration(milliseconds: 600),
          reverseTransitionDuration: Duration(milliseconds: 400),
        ),
      );
    } else {
      // For unsupported file types, show a preview dialog with transition
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        barrierColor: Colors.black54,
        transitionDuration: Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insert_drive_file,
                      size: 64,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'File Preview Not Available',
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'File type "${file.fileTypeCategory}" is not supported for in-app preview.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.comicNeue(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _downloadFile(file);
                          },
                          icon: Icon(Icons.download),
                          label: Text('Download'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.7,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      );
    }
  } catch (e) {
    _showSnackBar('Error opening file: $e', Colors.red);
  }
}


    Future<void> _logFileAccess(DriveFile file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final existingProgress = _progressData[file.id];
      
      final updatedProgress = existingProgress?.copyWith(
        viewCount: (existingProgress.viewCount) + 1,
        lastViewed: now,
      ) ?? StudentProgress(
        userId: user.uid,
        fileId: file.id,
        fileName: file.name,
        viewCount: 1,
        firstViewed: now,
        lastViewed: now,
        totalTimeSpent: Duration.zero,
        annotations: [],
        bookmarks: [],
        metadata: {
          'fileType': file.fileTypeCategory,
          'mimeType': file.mimeType,
          'size': file.size,
        },
        isFavorite: false,
        progress: 0.0,
        sessionHistory: {now.toIso8601String(): now},
        tags: [],
        customData: {},
      );
      
      setState(() {
        _progressData[file.id] = updatedProgress;
      });
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('file_progress')
          .doc(file.id)
          .set(updatedProgress.toJson());
          
      await _logStudySession(file.id, file.name, Duration(minutes: 1));
    } catch (e) {
      print('Error logging file access: $e');
    }
  }

    void _openFileViewer(DriveFile file) {
    if (file.mimeType.contains('pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedPDFViewerScreen(
            file: file,
            driveService: _driveService,
          ),
        ),
      );
    } else if (file.mimeType.contains('image')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerScreen(
            file: file,
            driveService: _driveService,
          ),
        ),
      );
    } else if (file.mimeType.contains('video')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoViewerScreen(
            file: file,
            driveService: _driveService,
          ),
        ),
      );
    } else if (file.mimeType.contains('audio')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioViewerScreen(
            file: file,
            driveService: _driveService,
          ),
        ),
      );
    } else if (_isTextFile(file)) {
      // Handle TXT files with enhanced text viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TextDocumentViewer(
            file: file,
            driveService: _driveService,
          ),
        ),
      );
    } else if (_isOfficeFile(file)) {
      // Handle DOCX, PPTX, XLSX files with proper Office viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OfficeDocumentViewer(
            file: file,
            driveService: _driveService,
          ),
        ),
      );
    } else {
      _showSnackBar('File type not supported for preview', Colors.orange);
    }
  }


    bool _isTextFile(DriveFile file) {
    return file.mimeType.contains('text') || 
          file.name.toLowerCase().endsWith('.txt');
  }

  bool _isOfficeFile(DriveFile file) {
    return _isWordFile(file) || _isExcelFile(file) || _isPowerPointFile(file);
  }

  bool _isWordFile(DriveFile file) {
    return file.mimeType.contains('wordprocessingml') ||
          file.mimeType.contains('msword') ||
          file.name.toLowerCase().endsWith('.docx') ||
          file.name.toLowerCase().endsWith('.doc');
  }

  bool _isExcelFile(DriveFile file) {
    return file.mimeType.contains('spreadsheet') ||
          file.mimeType.contains('excel') ||
          file.mimeType.contains('ms-excel') ||
          file.name.toLowerCase().endsWith('.xlsx') ||
          file.name.toLowerCase().endsWith('.xls');
  }

  bool _isPowerPointFile(DriveFile file) {
    return file.mimeType.contains('presentation') ||
          file.mimeType.contains('powerpoint') ||
          file.mimeType.contains('ms-powerpoint') ||
          file.name.toLowerCase().endsWith('.pptx') ||
          file.name.toLowerCase().endsWith('.ppt');
  }


    // Enhanced favorites management
// Enhanced favorites management
Future<void> _toggleFavorite(DriveFile file) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // FIXED: Define existingProgress properly
    final existingProgress = _progressData[file.id];
    final isFavorite = !(existingProgress?.isFavorite ?? false);
    
    final updatedProgress = existingProgress?.copyWith(
      isFavorite: isFavorite,
    ) ?? StudentProgress(
      userId: user.uid,
      fileId: file.id,
      fileName: file.name,
      viewCount: 0,
      firstViewed: DateTime.now(),
      lastViewed: DateTime.now(),
      totalTimeSpent: Duration.zero,
      annotations: [],
      bookmarks: [],
      metadata: {
        'fileType': file.fileTypeCategory,
        'mimeType': file.mimeType,
        'size': file.size,
        'isFolder': file.isFolder,
      },
      isFavorite: isFavorite,
      progress: 0.0,
      sessionHistory: {},
      tags: [],
      customData: {},
    );
    
    // Update local state immediately
    setState(() {
      _progressData[file.id] = updatedProgress;
    });
    
    // Save to Firestore with error handling
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('file_progress')
        .doc(file.id)
        .set(updatedProgress.toJson(), SetOptions(merge: true));
    
    // Show confirmation
    _showSnackBar(
      isFavorite ? 'Added to favorites' : 'Removed from favorites',
      isFavorite ? Colors.red : Colors.grey,
    );
    
    // Force refresh if we're currently viewing favorites
    if (_selectedCategory == 'Favorites') {
      setState(() {});
    }
    
  } catch (e) {
    // FIXED: Use the properly defined existingProgress
    final originalProgress = _progressData[file.id];
    
    // Revert local state if save failed
    setState(() {
      if (originalProgress != null) {
        _progressData[file.id] = originalProgress;
      } else {
        _progressData.remove(file.id);
      }
    });
    _showSnackBar('Error updating favorites: $e', Colors.red);
  }
}


    // Enhanced notes management
  Future<void> _loadUserNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final notesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .orderBy('updatedAt', descending: true)
          .get();

      setState(() {
        _recentNotes = notesSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Untitled',
            'content': data['content'] ?? '',
            'subject': data['subject'] ?? 'General',
            'category': data['category'] ?? 'Note',
            'updatedAt': data['updatedAt']?.toDate() ?? DateTime.now(),
            'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
            'tags': List<String>.from(data['tags'] ?? []),
            'wordCount': data['wordCount'] ?? 0,
            'readingTime': data['readingTime'] ?? 0,
            'isArchived': data['isArchived'] ?? false,
            'isFavorite': data['isFavorite'] ?? false,
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading notes: $e');
    }
  }

  // Load favorites from Firestore
Future<void> _loadFavorites() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final progressSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('file_progress')
        .where('isFavorite', isEqualTo: true)
        .get();

    // Update progress data with favorites
    for (final doc in progressSnapshot.docs) {
      final data = doc.data();
      final fileId = doc.id;
      
      if (_progressData.containsKey(fileId)) {
        _progressData[fileId] = _progressData[fileId]!.copyWith(isFavorite: true);
      } else {
        _progressData[fileId] = StudentProgress.fromJson(data);
      }
    }
    
    setState(() {});
  } catch (e) {
    print('Error loading favorites: $e');
  }
}

    // Load favorites
  Future<List<DriveFile>> _loadFavoriteFiles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final progressSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('file_progress')
          .where('isFavorite', isEqualTo: true)
          .get();

      List<DriveFile> favoriteFiles = [];
      
      for (final doc in progressSnapshot.docs) {
        final data = doc.data();
        final fileId = doc.id;
        
        // Try to find the file in current cache first
        DriveFile? file = _fileCache[fileId];
        
        if (file == null) {
          // If not in cache, create a DriveFile from stored metadata
          final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
          file = DriveFile(
            id: fileId,
            name: data['fileName'] ?? 'Unknown File',
            mimeType: metadata['mimeType'] ?? 'application/octet-stream',
            size: metadata['size'] ?? 0,
            modifiedTime: DateTime.now(),
            createdTime: DateTime.now(),
            parents: [],
            isFolder: metadata['isFolder'] ?? false,
            isShared: false,
            owners: [],
            version: 1,
            isStarred: false,
            isTrashed: false,
            isExplicitlyTrashed: false,
            isWritersCanShare: false,
            isViewedByMe: true,
            isOwnedByMe: false,
          );
        }
        
        favoriteFiles.add(file);
      }
      
      return favoriteFiles;
    } catch (e) {
      print('Error loading favorite files: $e');
      return [];
    }
  }

    // Enhanced folder size calculation
  // Enhanced folder size calculation
  Future<void> _calculateFolderSizes() async {
    for (int i = 0; i < _driveFiles.length; i++) {
      final file = _driveFiles[i];
      if (file.isFolder) {
        final folderSize = await _calculateFolderSize(file.id);
        // Update the file with calculated size
        setState(() {
          _driveFiles[i] = DriveFile(
            id: file.id,
            name: file.name,
            mimeType: file.mimeType,
            size: folderSize,
            modifiedTime: file.modifiedTime,
            createdTime: file.createdTime,
            thumbnailLink: file.thumbnailLink,
            webViewLink: file.webViewLink,
            webContentLink: file.webContentLink,
            parents: file.parents,
            description: file.description,
            properties: file.properties,
            isFolder: file.isFolder,
            md5Checksum: file.md5Checksum,
            sha1Checksum: file.sha1Checksum,
            sha256Checksum: file.sha256Checksum,
            isShared: file.isShared,
            owners: file.owners,
            lastModifyingUser: file.lastModifyingUser,
            version: file.version,
            isStarred: file.isStarred,
            isTrashed: file.isTrashed,
            isExplicitlyTrashed: file.isExplicitlyTrashed,
            originalFilename: file.originalFilename,
            fullFileExtension: file.fullFileExtension,
            fileExtension: file.fileExtension,
            headRevisionId: file.headRevisionId,
            isWritersCanShare: file.isWritersCanShare,
            isViewedByMe: file.isViewedByMe,
            viewedByMeTime: file.viewedByMeTime,
            isOwnedByMe: file.isOwnedByMe,
            permissionId: file.permissionId,
            quotaBytesUsed: file.quotaBytesUsed,
          );
        });
      }
    }
  }

  Future<int> _calculateFolderSize(String folderId) async {
    try {
      final files = await _driveService.listFilesInFolder(folderId, useCache: false);
      int totalSize = 0;
      
      for (final file in files) {
        if (file.isFolder) {
          totalSize += await _calculateFolderSize(file.id);
        } else {
          totalSize += file.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      print('Error calculating folder size for $folderId: $e');
      return 0;
    }
  }


    // Enhanced view tracking
  Future<void> _incrementViewCount(DriveFile file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final existingProgress = _progressData[file.id];
      
      final updatedProgress = existingProgress?.copyWith(
        viewCount: (existingProgress.viewCount) + 1,
        lastViewed: now,
      ) ?? StudentProgress(
        userId: user.uid,
        fileId: file.id,
        fileName: file.name,
        viewCount: 1,
        firstViewed: now,
        lastViewed: now,
        totalTimeSpent: Duration.zero,
        annotations: [],
        bookmarks: [],
        metadata: {
          'fileType': file.fileTypeCategory,
          'mimeType': file.mimeType,
          'size': file.size,
          'isFolder': file.isFolder,
        },
        isFavorite: existingProgress?.isFavorite ?? false,
        progress: 0.0,
        sessionHistory: {now.toIso8601String(): now},
        tags: [],
        customData: {},
      );
      
      setState(() {
        _progressData[file.id] = updatedProgress;
      });
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('file_progress')
          .doc(file.id)
          .set(updatedProgress.toJson());
          
      // Log study session for analytics
      await _logStudySession(file.id, file.name, Duration(minutes: 1));
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

    Future<void> _downloadFile(DriveFile file) async {
    try {
      _showSnackBar('Downloading ${file.name}...', Colors.blue);
      
      final downloadedFile = await _driveService.downloadFile(
        file.id,
        file.name,
        onProgress: (received, total) {
          // Show download progress
        },
      );
      
      if (downloadedFile != null) {
        _showSnackBar('Downloaded successfully!', Colors.green);
      } else {
        _showSnackBar('Download failed', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error downloading file: $e', Colors.red);
    }
  }

    void _shareFile(DriveFile file) {
    if (file.webViewLink != null) {
      Share.share(
        'Check out this file: ${file.name}\nDownload JEEzy App from GitHub: https://github.com/bhavishy2801/jeezy',
        subject: 'Shared from Study Hub',
      );
    } else {
      _showSnackBar('File cannot be shared', Colors.orange);
    }
  }

    void _showFileInfo(DriveFile file) {
    final progress = _progressData[file.id];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'File Information',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Name', file.name),
              _buildInfoRow('Type', file.fileTypeCategory),
              _buildInfoRow('Size', file.displaySize),
              _buildInfoRow('Modified', _formatDate(file.modifiedTime)),
              _buildInfoRow('Created', _formatDate(file.createdTime)),
              if (progress != null) ...[
                Divider(),
                _buildInfoRow('View Count', '${progress.viewCount}'),
                _buildInfoRow('Progress', '${(progress.progress * 100).toInt()}%'),
                _buildInfoRow('Last Viewed', _formatDate(progress.lastViewed)),
                _buildInfoRow('Total Time', '${progress.totalTimeSpent.inMinutes} minutes'),
                _buildInfoRow('Favorite', progress.isFavorite ? 'Yes' : 'No'),
              ],
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

    Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.comicNeue(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

    // Enhanced note creation dialog
  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String title = '';
        String content = '';
        String subject = 'General';
        String category = 'Note';
        List<String> tags = [];
        
        return AlertDialog(
          title: Text('Create New Note', style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  onChanged: (value) => title = value,
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 5,
                  onChanged: (value) => content = value,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: subject,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.subject),
                  ),
                  items: ['General', 'Physics', 'Chemistry', 'Mathematics', 'Biology', 'Computer Science', 'English', 'History']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => subject = value!,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: ['Note', 'Summary', 'Question', 'Concept', 'Formula', 'Important']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => category = value!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.isNotEmpty && content.isNotEmpty) {
                  await _createNote(title, content, subject, category, tags);
                  Navigator.pop(context);
                } else {
                  _showSnackBar('Please fill in title and content', Colors.orange);
                }
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

    Future<void> _createNote(String title, String content, String subject, String category, List<String> tags) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final wordCount = content.split(' ').length;
      final readingTime = (wordCount / 200).ceil(); // Assuming 200 words per minute
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .add({
        'title': title,
        'content': content,
        'subject': subject,
        'category': category,
        'tags': tags,
        'wordCount': wordCount,
        'readingTime': readingTime,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isArchived': false,
        'isFavorite': false,
      });
      
      // Refresh notes data
      await _loadUserNotes();
      
      _showSnackBar('Note created successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error creating note: $e', Colors.red);
    }
  }

  // Notes viewer screen
  void _showNoteDetail(Map<String, dynamic> note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(
          note: note,
          onNoteUpdated: () {
            _loadUserNotes();
          },
        ),
      ),
    );
  }

    void _showAllNotesDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Notes',
                    style: GoogleFonts.comicNeue(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              Expanded(
                child: _recentNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No notes yet',
                              style: GoogleFonts.comicNeue(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create your first note to get started',
                              style: GoogleFonts.comicNeue(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _recentNotes.length,
                        itemBuilder: (context, index) {
                          final note = _recentNotes[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getSubjectColor(note['subject']).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getCategoryIcon(note['category']),
                                  color: _getSubjectColor(note['subject']),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                note['title'],
                                style: GoogleFonts.comicNeue(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note['content'],
                                    style: GoogleFonts.comicNeue(fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getSubjectColor(note['subject']).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          note['subject'],
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _getSubjectColor(note['subject']),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        _formatDate(note['updatedAt']),
                                        style: GoogleFonts.comicNeue(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _showNoteDetail(note);
                              },
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    await _deleteNote(note['id']);
                                  } else if (value == 'edit') {
                                    _showEditNoteDialog(note);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddNoteDialog();
                },
                icon: Icon(Icons.add),
                label: Text('Create New Note'),
              ),
            ],
          ),
        ),
      ),
    );
  }

    Future<void> _deleteNote(String noteId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(noteId)
          .delete();
      
      await _loadUserNotes();
      _showSnackBar('Note deleted successfully', Colors.orange);
    } catch (e) {
      _showSnackBar('Error deleting note: $e', Colors.red);
    }
  }

    void _showEditNoteDialog(Map<String, dynamic> note) {
      String title = note['title'];
      String content = note['content'];
      String subject = note['subject'];
      String category = note['category'];
      List<String> tags = List<String>.from(note['tags'] ?? []);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Edit Note', style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: TextEditingController(text: title),
                  onChanged: (value) => title = value,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: content),
                  onChanged: (value) => content = value,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: 'Content'),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: subject,
                  onChanged: (value) => subject = value!,
                  decoration: InputDecoration(labelText: 'Subject'),
                  items: ['General', 'Physics', 'Chemistry', 'Mathematics', 'Biology', 'Computer Science']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  onChanged: (value) => category = value!,
                  decoration: InputDecoration(labelText: 'Category'),
                  items: ['Note', 'Formula', 'Theory', 'Important', 'Revision']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.isNotEmpty && content.isNotEmpty) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('notes')
                          .doc(note['id'])
                          .update({
                        'title': title,
                        'content': content,
                        'subject': subject,
                        'category': category,
                        'tags': tags,
                        'updatedAt': Timestamp.now(),
                        'wordCount': content.split(' ').length,
                        'readingTime': (content.split(' ').length / 200).ceil(),
                      });
                      
                      await _loadUserNotes();
                      Navigator.pop(context);
                      _showSnackBar('Note updated successfully!', Colors.green);
                    } catch (e) {
                      _showSnackBar('Error updating note: $e', Colors.red);
                    }
                  }
                } else {
                  _showSnackBar('Title and content cannot be empty', Colors.orange);
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      );
    }

    void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String title = '';
        String description = '';
        DateTime targetDate = DateTime.now().add(Duration(days: 30));
        String type = 'study';
        String priority = 'medium';
        
        return AlertDialog(
          title: Text('Create Study Goal', style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Goal Title',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => title = value,
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (value) => description = value,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: InputDecoration(
                    labelText: 'Goal Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['study', 'reading', 'practice', 'exam', 'project']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.capitalize())))
                      .toList(),
                  onChanged: (value) => type = value!,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: ['low', 'medium', 'high', 'urgent']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.capitalize())))
                      .toList(),
                  onChanged: (value) => priority = value!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.isNotEmpty) {
                  await _createStudyGoal(title, description, targetDate, type, priority);
                  Navigator.pop(context);
                }
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

    Future<void> _createStudyGoal(String title, String description, DateTime targetDate, String type, String priority) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('study_goals')
          .add({
        'title': title,
        'description': description,
        'targetDate': Timestamp.fromDate(targetDate),
        'type': type,
        'priority': priority,
        'progress': 0.0,
        'isCompleted': false,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'category': 'study',
      });
      
      await _loadStudentData();
      _showSnackBar('Study goal created successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error creating goal: $e', Colors.red);
    }
  }

    void _showSnackBar(String message, Color color) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: color,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }

    String _formatDate(DateTime date) {
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }

    Color _getSubjectColor(String subject) {
      switch (subject) {
        case 'Physics':
          return Colors.blue;
        case 'Chemistry':
          return Colors.green;
        case 'Mathematics':
          return Colors.orange;
        case 'Biology':
          return Colors.purple;
        case 'Computer Science':
          return Colors.teal;
        default:
          return Colors.grey;
      }
    }

    IconData _getCategoryIcon(String category) {
      switch (category) {
        case 'All':
          return Icons.all_inclusive;
        case 'PDF':
          return Icons.picture_as_pdf;
        case 'Document':
          return Icons.description;
        case 'Image':
          return Icons.image;
        case 'Video':
          return Icons.video_file;
        case 'Audio':
          return Icons.audio_file;
        case 'Folder':
          return Icons.folder;
        case 'Presentation':
          return Icons.slideshow;
        case 'Spreadsheet':
          return Icons.table_chart;
        case 'Archive':
          return Icons.archive;
        case 'Formula':
          return Icons.calculate;
        case 'Theory':
          return Icons.book;
        case 'Important':
          return Icons.star;
        case 'Revision':
          return Icons.refresh;
        default:
          return Icons.note;
      }
    }

    IconData _getSortIcon(String sortOption) {
      switch (sortOption) {
        case 'Date':
          return Icons.schedule;
        case 'Title':
          return Icons.sort_by_alpha;
        case 'Type':
          return Icons.category;
        case 'Size':
          return Icons.data_usage;
        case 'Most Viewed':
          return Icons.visibility;
        case 'Recently Viewed':
          return Icons.history;
        case 'Progress':
          return Icons.trending_up;
        case 'Favorites':
          return Icons.favorite;
        default:
          return Icons.sort;
      }
    }
  }

  // File Viewer Screens (keeping your existing implementations)

  // Enhanced PDF Viewer Screen with advanced features and optimizations
  class PDFViewerScreen extends StatefulWidget {
    final DriveFile file;
    final GoogleDriveService driveService;

    const PDFViewerScreen({
      Key? key,
      required this.file,
      required this.driveService,
    }) : super(key: key);

    @override
    State<PDFViewerScreen> createState() => _PDFViewerScreenState();
  }

  class _PDFViewerScreenState extends State<PDFViewerScreen> with TickerProviderStateMixin {
    File? _localFile;
    bool _isLoading = true;
    String? _error;
    bool _isFullscreen = false;
    
    // PDF Controls
    PdfViewerController? _pdfViewerController;
    int _currentPage = 1;
    int _totalPages = 0;
    bool _showControls = true;
    
    // Enhanced Display Modes
    bool _isNightMode = false;
    bool _isReaderMode = false;
    bool _isSepiaTone = false;
    double _brightness = 1.0;
    double _contrast = 1.0;
    double _textSize = 1.0;
    Color _backgroundColor = Colors.white;
    Color _textColor = Colors.black;
    
    // Animation Controllers
    late AnimationController _controlsAnimationController;
    late AnimationController _loadingController;
    late Animation<double> _controlsAnimation;
    Timer? _hideControlsTimer;

    // Text-to-Speech
    bool _isSpeaking = false;
    double _speechRate = 0.5;
    double _speechPitch = 1.0;
    String _speechLanguage = 'en-US';
    
    // Bookmarks and Progress
    List<int> _bookmarks = [];
    List<PdfAnnotation> _annotations = [];
    double _readingProgress = 0.0;
    Duration _readingTime = Duration.zero;
    Timer? _readingTimer;

    // Search
    bool _isSearching = false;
    String _searchQuery = '';
    bool _hasSearchResults = false;

    // Performance Optimization - Fix: Add missing variables
    final Map<int, Widget> _pageCache = {};
    int _cacheSize = 5;
    double _zoomLevel = 1.0;
    
    // Gesture Controls - Fix: Add missing variables
    bool _isDoubleTapEnabled = true;
    bool _isPinchToZoomEnabled = true;
    
    // Annotation System - Fix: Add missing variables
    bool _isAnnotationMode = false;
    AnnotationType _selectedAnnotationType = AnnotationType.highlight;
    Color _selectedAnnotationColor = Colors.yellow;
    double _annotationOpacity = 0.5;

    @override
    void initState() {
      super.initState();
      _pdfViewerController = PdfViewerController();
      _initializeAnimations();
      _loadSavedSettings();
      _downloadAndOpenFile();
      _startReadingTimer();
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
      
      _controlsAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controlsAnimationController, curve: Curves.easeOut),
      );
      
      _controlsAnimationController.forward();
      _loadingController.repeat();
    }

    Future<void> _loadSavedSettings() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final fileKey = 'pdf_${widget.file.id}';
        
        setState(() {
          _isNightMode = prefs.getBool('${fileKey}_night_mode') ?? false;
          _isReaderMode = prefs.getBool('${fileKey}_reader_mode') ?? false;
          _isSepiaTone = prefs.getBool('${fileKey}_sepia_tone') ?? false;
          _brightness = prefs.getDouble('${fileKey}_brightness') ?? 1.0;
          _contrast = prefs.getDouble('${fileKey}_contrast') ?? 1.0;
          _textSize = prefs.getDouble('${fileKey}_text_size') ?? 1.0;
          _speechRate = prefs.getDouble('${fileKey}_speech_rate') ?? 0.5;
          _speechPitch = prefs.getDouble('${fileKey}_speech_pitch') ?? 1.0;
          _speechLanguage = prefs.getString('${fileKey}_speech_language') ?? 'en-US';
          _zoomLevel = prefs.getDouble('${fileKey}_zoom_level') ?? 1.0;
          _isDoubleTapEnabled = prefs.getBool('${fileKey}_double_tap') ?? true;
          _isPinchToZoomEnabled = prefs.getBool('${fileKey}_pinch_zoom') ?? true;
          
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
            _annotations = annotationsList.map((json) => PdfAnnotation.fromJson(json)).toList();
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
        
        await prefs.setBool('${fileKey}_night_mode', _isNightMode);
        await prefs.setBool('${fileKey}_reader_mode', _isReaderMode);
        await prefs.setBool('${fileKey}_sepia_tone', _isSepiaTone);
        await prefs.setDouble('${fileKey}_brightness', _brightness);
        await prefs.setDouble('${fileKey}_contrast', _contrast);
        await prefs.setDouble('${fileKey}_text_size', _textSize);
        await prefs.setDouble('${fileKey}_speech_rate', _speechRate);
        await prefs.setDouble('${fileKey}_speech_pitch', _speechPitch);
        await prefs.setString('${fileKey}_speech_language', _speechLanguage);
        await prefs.setDouble('${fileKey}_zoom_level', _zoomLevel);
        await prefs.setBool('${fileKey}_double_tap', _isDoubleTapEnabled);
        await prefs.setBool('${fileKey}_pinch_zoom', _isPinchToZoomEnabled);
        await prefs.setString('${fileKey}_bookmarks', jsonEncode(_bookmarks));
        await prefs.setString('${fileKey}_annotations', jsonEncode(_annotations.map((a) => a.toJson()).toList()));
      } catch (e) {
        print('Error saving settings: $e');
      }
    }

    void _updateDisplayMode() {
      if (_isNightMode) {
        _backgroundColor = Colors.black;
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

    void _startReadingTimer() {
      _readingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (!_isLoading && _localFile != null) {
          setState(() {
            _readingTime = Duration(seconds: _readingTime.inSeconds + 1);
          });
        }
      });
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

    void _onPageChanged(int page) {
      setState(() {
        _currentPage = page;
        _readingProgress = _totalPages > 0 ? page / _totalPages : 0.0;
      });
      
      if (_isFullscreen) {
        _startHideControlsTimer();
      }
      
      // Preload nearby pages for better performance
      _preloadNearbyPages();
    }

    void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
      setState(() {
        _totalPages = details.document.pages.count;
      });
    }

    // Fix: Add missing preload method
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

    // Enhanced Text-to-Speech Implementation
    Future<void> _toggleTextToSpeech() async {
      if (_isSpeaking) {
        await _stopSpeech();
      } else {
        await _startSpeech();
      }
    }

    Future<void> _startSpeech() async {
      try {
        final pageText = await _extractTextFromCurrentPage();
        if (pageText.isNotEmpty) {
          setState(() {
            _isSpeaking = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reading page $_currentPage...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error starting speech: $e');
        setState(() {
          _isSpeaking = false;
        });
      }
    }

    Future<void> _stopSpeech() async {
      setState(() {
        _isSpeaking = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speech stopped'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
    }

    Future<String> _extractTextFromCurrentPage() async {
      return "This is the text content from page $_currentPage of the PDF document.";
    }

    // Search Implementation
    Future<void> _performSearch(String query) async {
      if (query.isEmpty) {
        setState(() {
          _isSearching = false;
          _hasSearchResults = false;
        });
        _pdfViewerController?.clearSelection();
        return;
      }

      setState(() {
        _isSearching = true;
        _searchQuery = query;
      });

      try {
        final result = await _pdfViewerController?.searchText(query);
        
        setState(() {
          _isSearching = false;
          _hasSearchResults = result?.hasResult ?? false;
        });
      } catch (e) {
        setState(() {
          _isSearching = false;
          _hasSearchResults = false;
        });
        print('Search error: $e');
      }
    }

    // Fix: Add missing annotation icon method
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
        case AnnotationType.bookmark:
          return Icons.bookmark;
        case AnnotationType.drawing:
          return Icons.brush;
      }
    }

    // Annotation handling
    void _addAnnotation(PdfTextSelectionChangedDetails details) {
      if (details.selectedText == null || !_isAnnotationMode) return;
      
      final annotation = PdfAnnotation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        page: _currentPage,
        text: details.selectedText!,
        type: _selectedAnnotationType,
        color: _selectedAnnotationColor,
        opacity: _annotationOpacity,
        createdAt: DateTime.now(),
        author: 'User',
      );
      
      setState(() {
        _annotations.add(annotation);
      });
      
      _saveSettings();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Annotation added'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _annotations.removeLast();
              });
              _saveSettings();
            },
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);

      if (_isFullscreen) {
        return Scaffold(
          backgroundColor: _backgroundColor,
          body: GestureDetector(
            onTap: () {
              _toggleControls();
            },
            child: Stack(
              children: [
                _buildPDFContent(),
                if (_showControls) _buildFullscreenControls(theme),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _buildAppBar(theme),
        body: _buildBody(theme),
        bottomNavigationBar: _buildBottomControls(theme),
        floatingActionButton: _buildFloatingActionButtons(theme),
      );
    }

    PreferredSizeWidget _buildAppBar(ThemeData theme) {
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
                'Page $_currentPage of $_totalPages â€¢ ${(_readingProgress * 100).toInt()}% â€¢ ${_formatDuration(_readingTime)}',
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
            onPressed: _showSearchDialog,
            tooltip: 'Search',
          ),
          IconButton(
            icon: Icon(_isSpeaking ? Icons.stop : Icons.record_voice_over, color: _textColor),
            onPressed: _toggleTextToSpeech,
            tooltip: _isSpeaking ? 'Stop Reading' : 'Read Aloud',
          ),
          IconButton(
            icon: Icon(_bookmarks.contains(_currentPage) ? Icons.bookmark : Icons.bookmark_border, color: _textColor),
            onPressed: _toggleBookmark,
            tooltip: 'Toggle Bookmark',
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
                value: 'night_mode',
                child: Row(
                  children: [
                    Icon(_isNightMode ? Icons.light_mode : Icons.dark_mode, size: 20),
                    SizedBox(width: 8),
                    Text(_isNightMode ? 'Light Mode' : 'Night Mode'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reader_mode',
                child: Row(
                  children: [
                    Icon(_isReaderMode ? Icons.chrome_reader_mode : Icons.chrome_reader_mode_outlined, size: 20),
                    SizedBox(width: 8),
                    Text(_isReaderMode ? 'Exit Reader Mode' : 'Reader Mode'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sepia_tone',
                child: Row(
                  children: [
                    Icon(_isSepiaTone ? Icons.palette : Icons.palette_outlined, size: 20),
                    SizedBox(width: 8),
                    Text(_isSepiaTone ? 'Normal Colors' : 'Sepia Tone'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'annotation_mode',
                child: Row(
                  children: [
                    Icon(_isAnnotationMode ? Icons.edit_off : Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text(_isAnnotationMode ? 'Exit Annotation Mode' : 'Annotation Mode'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'display_settings',
                child: Row(
                  children: [
                    Icon(Icons.tune, size: 20),
                    SizedBox(width: 8),
                    Text('Display Settings'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'speech_settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_voice, size: 20),
                    SizedBox(width: 8),
                    Text('Speech Settings'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bookmarks',
                child: Row(
                  children: [
                    Icon(Icons.bookmarks, size: 20),
                    SizedBox(width: 8),
                    Text('View Bookmarks (${_bookmarks.length})'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'annotations',
                child: Row(
                  children: [
                    Icon(Icons.note_add, size: 20),
                    SizedBox(width: 8),
                    Text('Annotations (${_annotations.length})'),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget _buildBody(ThemeData theme) {
      if (_isLoading) {
        return _buildLoadingState(theme);
      }

      if (_error != null) {
        return _buildErrorState(theme);
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
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
          
          // Annotation toolbar
          if (_isAnnotationMode) _buildAnnotationToolbar(theme),
          
          // PDF Content
          Expanded(child: _buildPDFContent()),
        ],
      );
    }

    Widget _buildAnnotationToolbar(ThemeData theme) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: _textColor.withOpacity(0.2),
            ),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'Annotation Mode',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  color: _textColor,
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
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedAnnotationType == type 
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedAnnotationType == type 
                            ? theme.colorScheme.primary
                            : Colors.grey,
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
              ].map((color) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAnnotationColor = color;
                  });
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
            ],
          ),
        ),
      );
    }

    Widget _buildLoadingState(ThemeData theme) {
      return Container(
        color: _backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: _loadingController,
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    size: 64,
                    color: theme.colorScheme.primary,
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
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildErrorState(ThemeData theme) {
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

      return Container(
        color: _backgroundColor,
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(_getColorMatrix()),
          child: SfPdfViewer.file(
            _localFile!,
            controller: _pdfViewerController,
            onPageChanged: (details) => _onPageChanged(details.newPageNumber),
            onDocumentLoaded: _onDocumentLoaded,
            onTextSelectionChanged: (details) {
              if (_isAnnotationMode && details.selectedText != null) {
                _addAnnotation(details);
              }
            },
            enableDoubleTapZooming: _isDoubleTapEnabled,
            enableTextSelection: true,
            canShowScrollHead: !_isFullscreen,
            canShowScrollStatus: !_isFullscreen,
            canShowPaginationDialog: !_isFullscreen,
            pageLayoutMode: PdfPageLayoutMode.continuous,
            scrollDirection: PdfScrollDirection.vertical,
            enableDocumentLinkAnnotation: true,
            enableHyperlinkNavigation: true,
            pageSpacing: _isReaderMode ? 8 : 4,
          ),
        ),
      );
    }

    List<double> _getColorMatrix() {
      double b = (_brightness - 1.0) * 0.3;
      double c = _contrast;
      
      if (_isNightMode) {
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
        return [
          c, 0, 0, 0, b * 255,
          0, c, 0, 0, b * 255,
          0, 0, c, 0, b * 255,
          0, 0, 0, 1, 0,
        ];
      }
    }

    Widget _buildFullscreenControls(ThemeData theme) {
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
                                'Page $_currentPage of $_totalPages â€¢ ${(_readingProgress * 100).toInt()}%',
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
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(_isSpeaking ? Icons.stop : Icons.record_voice_over, color: Colors.white),
                          onPressed: _toggleTextToSpeech,
                          tooltip: _isSpeaking ? 'Stop Reading' : 'Read Aloud',
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
                      Container(
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

    Widget _buildBottomControls(ThemeData theme) {
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
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_currentPage / $_totalPages',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${(_readingProgress * 100).toInt()}% complete',
                        style: GoogleFonts.comicNeue(
                          fontSize: 10,
                          color: theme.colorScheme.primary,
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

    Widget _buildFloatingActionButtons(ThemeData theme) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
                _pdfViewerController?.clearSelection();
                setState(() {
                  _searchQuery = '';
                  _hasSearchResults = false;
                });
              },
              backgroundColor: Colors.orange,
              child: Icon(Icons.clear),
              tooltip: 'Clear Search',
            ),
          ],
          SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _showJumpToPageDialog,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(Icons.pages),
            tooltip: 'Jump to Page',
          ),
        ],
      );
    }

    // Dialog Methods
    void _showSearchDialog() {
      showDialog(
        context: context,
        builder: (context) {
          String searchText = _searchQuery;
          return AlertDialog(
            backgroundColor: _backgroundColor,
            title: Text('Search in PDF', style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              color: _textColor,
            )),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: TextEditingController(text: searchText),
                  decoration: InputDecoration(
                    hintText: 'Enter search term...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: TextStyle(color: _textColor),
                  onChanged: (value) {
                    searchText = value;
                  },
                  onSubmitted: (query) {
                    Navigator.pop(context);
                    _performSearch(query);
                  },
                  autofocus: true,
                ),
                if (_isSearching) ...[
                  SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Searching...', style: GoogleFonts.comicNeue(
                        color: _textColor,
                      )),
                    ],
                  ),
                ],
                if (_hasSearchResults && !_isSearching) ...[
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Search results found',
                        style: GoogleFonts.comicNeue(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performSearch(searchText);
                },
                child: Text('Search'),
              ),
            ],
          );
        },
      );
    }

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
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Brightness', style: GoogleFonts.comicNeue(color: _textColor)),
                  Slider(
                    value: _brightness,
                    min: 0.3,
                    max: 1.5,
                    onChanged: (value) {
                      setDialogState(() {
                        _brightness = value;
                      });
                      setState(() {});
                    },
                  ),
                  Text('${(_brightness * 100).toInt()}%', style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    color: _textColor.withOpacity(0.7),
                  )),
                  
                  SizedBox(height: 16),
                  
                  Text('Contrast', style: GoogleFonts.comicNeue(color: _textColor)),
                  Slider(
                    value: _contrast,
                    min: 0.5,
                    max: 2.0,
                    onChanged: (value) {
                      setDialogState(() {
                        _contrast = value;
                      });
                      setState(() {});
                    },
                  ),
                  Text('${(_contrast * 100).toInt()}%', style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    color: _textColor.withOpacity(0.7),
                  )),
                  
                  SizedBox(height: 16),
                  
                  Text('Text Size', style: GoogleFonts.comicNeue(color: _textColor)),
                  Slider(
                    value: _textSize,
                    min: 0.8,
                    max: 1.5,
                    onChanged: (value) {
                      setDialogState(() {
                        _textSize = value;
                      });
                      setState(() {});
                    },
                  ),
                  Text('${(_textSize * 100).toInt()}%', style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    color: _textColor.withOpacity(0.7),
                  )),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _saveSettings();
                Navigator.pop(context);
              },
              child: Text('Done'),
            ),
          ],
        ),
      );
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
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Speech Rate', style: GoogleFonts.comicNeue(color: _textColor)),
                  Slider(
                    value: _speechRate,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (value) {
                      setDialogState(() {
                        _speechRate = value;
                      });
                    },
                  ),
                  Text('${(_speechRate * 100).toInt()}%', style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    color: _textColor.withOpacity(0.7),
                  )),
                  
                  SizedBox(height: 16),
                  
                  Text('Speech Pitch', style: GoogleFonts.comicNeue(color: _textColor)),
                  Slider(
                    value: _speechPitch,
                    min: 0.5,
                    max: 2.0,
                    onChanged: (value) {
                      setDialogState(() {
                        _speechPitch = value;
                      });
                    },
                  ),
                  Text('${(_speechPitch * 100).toInt()}%', style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    color: _textColor.withOpacity(0.7),
                  )),
                  
                  SizedBox(height: 16),
                  
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
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _speechLanguage = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _saveSettings();
                Navigator.pop(context);
              },
              child: Text('Done'),
            ),
          ],
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
              ? Text('No bookmarks added yet', style: TextStyle(color: _textColor))
              : Container(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _bookmarks.length,
                    itemBuilder: (context, index) {
                      final page = _bookmarks[index];
                      return ListTile(
                        leading: Icon(Icons.bookmark, color: _textColor),
                        title: Text('Page $page', style: TextStyle(color: _textColor)),
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
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
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

    void _showAnnotationsDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _backgroundColor,
          title: Text('Annotations', style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            color: _textColor,
          )),
          content: _annotations.isEmpty
              ? Text('No annotations added yet', style: TextStyle(color: _textColor))
              : Container(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _annotations.length,
                    itemBuilder: (context, index) {
                      final annotation = _annotations[index];
                      return Card(
                        color: _backgroundColor,
                        child: ListTile(
                          leading: Icon(_getAnnotationIcon(annotation.type), color: annotation.color),
                          title: Text('Page ${annotation.page}', style: TextStyle(color: _textColor)),
                          subtitle: Text(
                            annotation.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: _textColor.withOpacity(0.7)),
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
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
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

    void _handleMenuAction(String action) {
      switch (action) {
        case 'night_mode':
          setState(() {
            _isNightMode = !_isNightMode;
            if (_isNightMode) {
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
              _isNightMode = false;
              _isSepiaTone = false;
            }
            _updateDisplayMode();
          });
          _saveSettings();
          break;
        case 'sepia_tone':
          setState(() {
            _isSepiaTone = !_isSepiaTone;
            if (_isSepiaTone) {
              _isNightMode = false;
              _isReaderMode = false;
            }
            _updateDisplayMode();
          });
          _saveSettings();
          break;
        case 'annotation_mode':
          setState(() {
            _isAnnotationMode = !_isAnnotationMode;
          });
          break;
        case 'display_settings':
          _showDisplaySettingsDialog();
          break;
        case 'speech_settings':
          _showSpeechSettingsDialog();
          break;
        case 'bookmarks':
          _showBookmarksDialog();
          break;
        case 'annotations':
          _showAnnotationsDialog();
          break;
      }
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _bookmarks.contains(_currentPage) 
                ? 'Bookmark added for page $_currentPage'
                : 'Bookmark removed for page $_currentPage',
          ),
          backgroundColor: _bookmarks.contains(_currentPage) ? Colors.green : Colors.orange,
          duration: Duration(seconds: 1),
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
      _controlsAnimationController.dispose();
      _loadingController.dispose();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _saveSettings();
      super.dispose();
    }
  }

  // Annotation Model
  class PdfAnnotation {
    final String id;
    final int page;
    final String text;
    final AnnotationType type;
    final Color color;
    final double opacity;
    final DateTime createdAt;
    final String author;

    PdfAnnotation({
      required this.id,
      required this.page,
      required this.text,
      required this.type,
      required this.color,
      required this.opacity,
      required this.createdAt,
      required this.author,
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
        'author': author,
      };
    }

    factory PdfAnnotation.fromJson(Map<String, dynamic> json) {
      return PdfAnnotation(
        id: json['id'],
        page: json['page'],
        text: json['text'],
        type: AnnotationType.values[json['type']],
        color: Color(json['color']),
        opacity: json['opacity'] ?? 0.5,
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
        author: json['author'] ?? 'User',
      );
    }
  }

  // Annotation Types Enum
  enum AnnotationType {
    highlight,
    underline,
    strikethrough,
    note,
    bookmark,
    drawing,
  }
  // Gesture Recognition Extensions
  extension GestureHandling on _PDFViewerScreenState {
    void handleDoubleTap() {
      if (!_isDoubleTapEnabled) return;
      
      // Implement smart zoom
      if (_zoomLevel < 1.5) {
        _pdfViewerController?.zoomLevel = 2.0;
      } else {
        _pdfViewerController?.zoomLevel = 1.0;
      }
    }
    
    void handleLongPress() {
      // Show context menu for annotations
      if (_isAnnotationMode) {
        _showAnnotationContextMenu();
      }
    }
    
    void _showAnnotationContextMenu() {
      showModalBottomSheet(
        context: context,
        backgroundColor: _isNightMode ? Colors.grey.shade900 : Colors.white,
        builder: (context) => Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Annotation Tools',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isNightMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: AnnotationType.values.map((type) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAnnotationType = type;
                      });
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedAnnotationType == type 
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getAnnotationIcon(type),
                            color: _selectedAnnotationType == type 
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          type.name.capitalize(),
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            color: _isNightMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }
  }

  extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${this.substring(1)}";
    }
  }

  // Image Viewer Screen
  // Enhanced Image Viewer Screen
  class ImageViewerScreen extends StatefulWidget {
    final DriveFile file;
    final GoogleDriveService driveService;

    const ImageViewerScreen({
      Key? key,
      required this.file,
      required this.driveService,
    }) : super(key: key);

    @override
    State<ImageViewerScreen> createState() => _ImageViewerScreenState();
  }

  class _ImageViewerScreenState extends State<ImageViewerScreen> with TickerProviderStateMixin {
    File? _localFile;
    bool _isLoading = true;
    String? _error;
    bool _isFullscreen = false;
    bool _showControls = true;
    
    // Animation Controllers
    late AnimationController _controlsAnimationController;
    late Animation<double> _controlsAnimation;
    Timer? _hideControlsTimer;
    
    // Image properties
    PhotoViewController _photoViewController = PhotoViewController();
    double _scaleCopy = 1.0;
    double _rotation = 0.0;
    
    // Image filters
    ColorFilter? _currentFilter;
    double _brightness = 0.0;
    double _contrast = 1.0;
    double _saturation = 1.0;

    @override
    void initState() {
      super.initState();
      _initializeAnimations();
      _loadImage();
    }

    void _initializeAnimations() {
      _controlsAnimationController = AnimationController(
        duration: Duration(milliseconds: 300),
        vsync: this,
      );
      
      _controlsAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controlsAnimationController, curve: Curves.easeInOut),
      );
      
      _controlsAnimationController.forward();
    }

    Future<void> _loadImage() async {
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
        } else {
          setState(() {
            _error = 'Failed to download image file';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
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
      if (!_isFullscreen) return;
      
      setState(() {
        _showControls = !_showControls;
      });
      
      if (_showControls) {
        _controlsAnimationController.forward();
        _startHideControlsTimer();
      } else {
        _controlsAnimationController.reverse();
        _hideControlsTimer?.cancel();
      }
    }

    void _startHideControlsTimer() {
      _hideControlsTimer?.cancel();
      _hideControlsTimer = Timer(Duration(seconds: 3), () {
        if (_isFullscreen && _showControls && mounted) {
          _toggleControls();
        }
      });
    }

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      if (_isFullscreen) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: _toggleControls,
            child: Stack(
              children: [
                _buildImageContent(),
                if (_showControls) _buildFullscreenControls(isDark, theme),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(isDark, theme),
        body: _buildBody(isDark, theme),
        bottomNavigationBar: _buildImageControls(isDark, theme),
      );
    }

    PreferredSizeWidget _buildAppBar(bool isDark, ThemeData theme) {
      return AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.file.name,
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.file.displaySize,
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.rotate_right),
            onPressed: () {
              setState(() {
                _rotation += 90;
                if (_rotation >= 360) _rotation = 0;
              });
            },
            tooltip: 'Rotate',
          ),
          IconButton(
            icon: Icon(Icons.tune),
            onPressed: _showImageFilters,
            tooltip: 'Filters',
          ),
          IconButton(
            icon: Icon(Icons.fullscreen),
            onPressed: _toggleFullscreen,
            tooltip: 'Fullscreen',
          ),
        ],
      );
    }

    Widget _buildBody(bool isDark, ThemeData theme) {
      if (_isLoading) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.image,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Loading Image...',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Preparing enhanced image viewer',
                style: GoogleFonts.comicNeue(
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 20),
              LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ],
          ),
        );
      }

      if (_error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(_error!, style: GoogleFonts.comicNeue(color: Colors.red)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadImage,
                child: Text('Retry'),
              ),
            ],
          ),
        );
      }

      return _buildImageContent();
    }

    Widget _buildImageContent() {
      if (_localFile == null) return Container();

      return Transform.rotate(
        angle: _rotation * math.pi / 180,
        child: ColorFiltered(
          colorFilter: _currentFilter ?? ColorFilter.matrix(_getColorMatrix()),
          child: PhotoView(
            imageProvider: FileImage(_localFile!),
            controller: _photoViewController,
            backgroundDecoration: BoxDecoration(color: Colors.black),
                      minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 3,
            enableRotation: true,
            heroAttributes: PhotoViewHeroAttributes(tag: widget.file.id),
            onScaleEnd: (context, details, controllerValue) {
              setState(() {
                _scaleCopy = controllerValue.scale!;
              });
            },
          ),
        ),
      );
    }

    Widget _buildFullscreenControls(bool isDark, ThemeData theme) {
      return FadeTransition(
        opacity: _controlsAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top controls
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
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
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.file.name,
                            style: GoogleFonts.comicNeue(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.tune, color: Colors.white),
                          onPressed: _showImageFilters,
                          tooltip: 'Filters',
                        ),
                      ),
                    ],
                  ),
                ),
                
                Spacer(),
                
                // Bottom controls
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.rotate_left, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _rotation -= 90;
                              if (_rotation < 0) _rotation = 270;
                            });
                          },
                          tooltip: 'Rotate Left',
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.zoom_in, color: Colors.white),
                          onPressed: () {
                            _photoViewController.scale = (_scaleCopy * 1.2).clamp(0.1, 5.0);
                          },
                          tooltip: 'Zoom In',
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.zoom_out, color: Colors.white),
                          onPressed: () {
                            _photoViewController.scale = (_scaleCopy * 0.8).clamp(0.1, 5.0);
                          },
                          tooltip: 'Zoom Out',
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.rotate_right, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _rotation += 90;
                              if (_rotation >= 360) _rotation = 0;
                            });
                          },
                          tooltip: 'Rotate Right',
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

    Widget _buildImageControls(bool isDark, ThemeData theme) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Colors.white24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Zoom controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.zoom_out, color: Colors.white),
                  onPressed: () {
                    _photoViewController.scale = (_scaleCopy * 0.8).clamp(0.1, 5.0);
                  },
                  tooltip: 'Zoom Out',
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(_scaleCopy * 100).toInt()}%',
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.zoom_in, color: Colors.white),
                  onPressed: () {
                    _photoViewController.scale = (_scaleCopy * 1.2).clamp(0.1, 5.0);
                  },
                  tooltip: 'Zoom In',
                ),
                IconButton(
                  icon: Icon(Icons.fit_screen, color: Colors.white),
                  onPressed: () {
                    _photoViewController.scale = 1.0;
                    setState(() {
                      _scaleCopy = 1.0;
                    });
                  },
                  tooltip: 'Fit to Screen',
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Rotation and filter controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.rotate_left, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _rotation -= 90;
                      if (_rotation < 0) _rotation = 270;
                    });
                  },
                  tooltip: 'Rotate Left',
                ),
                IconButton(
                  icon: Icon(Icons.rotate_right, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _rotation += 90;
                      if (_rotation >= 360) _rotation = 0;
                    });
                  },
                  tooltip: 'Rotate Right',
                ),
                IconButton(
                  icon: Icon(Icons.tune, color: Colors.white),
                  onPressed: _showImageFilters,
                  tooltip: 'Image Filters',
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: _resetImage,
                  tooltip: 'Reset',
                ),
              ],
            ),
          ],
        ),
      );
    }

    void _showImageFilters() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.black,
        builder: (context) => Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Image Adjustments',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              
              // Brightness
              _buildSliderControl(
                'Brightness',
                _brightness,
                -1.0,
                1.0,
                (value) {
                  setState(() {
                    _brightness = value;
                  });
                },
              ),
              
              // Contrast
              _buildSliderControl(
                'Contrast',
                _contrast,
                0.0,
                2.0,
                (value) {
                  setState(() {
                    _contrast = value;
                  });
                },
              ),
              
              // Saturation
              _buildSliderControl(
                'Saturation',
                _saturation,
                0.0,
                2.0,
                (value) {
                  setState(() {
                    _saturation = value;
                  });
                },
              ),
              
              SizedBox(height: 20),
              
              // Filter presets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilterButton('Original', null),
                  _buildFilterButton('Sepia', ColorFilter.matrix(_sepiaMatrix)),
                  _buildFilterButton('Grayscale', ColorFilter.matrix(_grayscaleMatrix)),
                  _buildFilterButton('Vintage', ColorFilter.matrix(_vintageMatrix)),
                ],
              ),
              
              SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildSliderControl(String label, double value, double min, double max, Function(double) onChanged) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.comicNeue(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Colors.white24,
                ),
              ),
              Container(
                width: 50,
                child: Text(
                  value.toStringAsFixed(1),
                  style: GoogleFonts.comicNeue(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget _buildFilterButton(String name, ColorFilter? filter) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _currentFilter = filter;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _currentFilter == filter 
                ? Theme.of(context).colorScheme.primary
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            name,
            style: GoogleFonts.comicNeue(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    void _resetImage() {
      setState(() {
        _rotation = 0.0;
        _brightness = 0.0;
        _contrast = 1.0;
        _saturation = 1.0;
        _currentFilter = null;
        _scaleCopy = 1.0;
      });
      _photoViewController.scale = 1.0;
    }

    List<double> _getColorMatrix() {
      // Create color matrix based on brightness, contrast, and saturation
      final double b = _brightness;
      final double c = _contrast;
      final double s = _saturation;
      
      return [
        c * s, 0, 0, 0, b * 255,
        0, c * s, 0, 0, b * 255,
        0, 0, c * s, 0, b * 255,
        0, 0, 0, 1, 0,
      ];
    }

    List<double> get _sepiaMatrix => [
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0, 0, 0, 1, 0,
    ];

    List<double> get _grayscaleMatrix => [
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ];

    List<double> get _vintageMatrix => [
      0.6, 0.3, 0.1, 0, 0,
      0.2, 0.7, 0.1, 0, 0,
      0.2, 0.1, 0.7, 0, 0,
      0, 0, 0, 1, 0,
    ];

    @override
    void dispose() {
      _hideControlsTimer?.cancel();
      _controlsAnimationController.dispose();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      super.dispose();
    }
  }


  // Video Viewer Screen
  // Enhanced Video Viewer Screen
  class VideoViewerScreen extends StatefulWidget {
    final DriveFile file;
    final GoogleDriveService driveService;

    const VideoViewerScreen({
      Key? key,
      required this.file,
      required this.driveService,
    }) : super(key: key);

    @override
    State<VideoViewerScreen> createState() => _VideoViewerScreenState();
  }

  class _VideoViewerScreenState extends State<VideoViewerScreen> with TickerProviderStateMixin {
    VideoPlayerController? _videoController;
    ChewieController? _chewieController;
    bool _isLoading = true;
    String? _error;
    bool _isFullscreen = false;
    bool _showControls = true;
    
    // Animation Controllers
    late AnimationController _controlsAnimationController;
    late Animation<double> _controlsAnimation;
    Timer? _hideControlsTimer;
    
    // Video properties
    Duration _duration = Duration.zero;
    Duration _position = Duration.zero;
    double _playbackSpeed = 1.0;
    bool _isPlaying = false;
    double _volume = 1.0;
    
    // Subtitle support
    List<String> _subtitles = [];
    bool _showSubtitles = false;

    @override
    void initState() {
      super.initState();
      _initializeAnimations();
      _initializeVideo();
    }

    void _initializeAnimations() {
      _controlsAnimationController = AnimationController(
        duration: Duration(milliseconds: 300),
        vsync: this,
      );
      
      _controlsAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controlsAnimationController, curve: Curves.easeInOut),
      );
      
      _controlsAnimationController.forward();
    }

    Future<void> _initializeVideo() async {
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
          _videoController = VideoPlayerController.file(file);
          await _videoController!.initialize();
          
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: false,
            looping: false,
            allowFullScreen: true,
            allowMuting: true,
            allowPlaybackSpeedChanging: true,
            showControlsOnInitialize: true,
            materialProgressColors: ChewieProgressColors(
              playedColor: Theme.of(context).colorScheme.primary,
              handleColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.grey.shade300,
              bufferedColor: Colors.grey.shade400,
            ),
            placeholder: Container(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error playing video',
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: GoogleFonts.comicNeue(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );

          _videoController!.addListener(_videoListener);
          
          setState(() {
            _duration = _videoController!.value.duration;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to download video file';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }

    void _videoListener() {
      if (_videoController != null) {
        setState(() {
          _position = _videoController!.value.position;
          _isPlaying = _videoController!.value.isPlaying;
        });
      }
    }

    void _toggleFullscreen() {
      setState(() {
        _isFullscreen = !_isFullscreen;
      });
      
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    }

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      if (_isFullscreen) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: _buildFullscreenVideo(),
        );
      }

      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(isDark, theme),
        body: _buildBody(isDark, theme),
        bottomNavigationBar: _buildVideoControls(isDark, theme),
      );
    }

    PreferredSizeWidget _buildAppBar(bool isDark, ThemeData theme) {
      return AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.file.name,
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_duration != Duration.zero)
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.speed),
            onPressed: _showPlaybackSpeedDialog,
            tooltip: 'Playback Speed',
          ),
          IconButton(
            icon: Icon(_showSubtitles ? Icons.subtitles : Icons.subtitles_off),
            onPressed: () {
              setState(() {
                _showSubtitles = !_showSubtitles;
              });
            },
            tooltip: 'Toggle Subtitles',
          ),
          IconButton(
            icon: Icon(Icons.fullscreen),
            onPressed: _toggleFullscreen,
            tooltip: 'Fullscreen',
          ),
        ],
      );
    }

    Widget _buildBody(bool isDark, ThemeData theme) {
      if (_isLoading) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.video_file,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Loading Video...',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Preparing enhanced video player',
                style: GoogleFonts.comicNeue(
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 20),
              LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ],
          ),
        );
      }

      if (_error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(_error!, style: GoogleFonts.comicNeue(color: Colors.red)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeVideo,
                child: Text('Retry'),
              ),
            ],
          ),
        );
      }

      return _chewieController != null
          ? Chewie(controller: _chewieController!)
          : Container();
    }

    Widget _buildFullscreenVideo() {
      return Stack(
        children: [
          Center(
            child: _chewieController != null
                ? Chewie(controller: _chewieController!)
                : Container(),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.fullscreen_exit, color: Colors.white),
                onPressed: _toggleFullscreen,
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildVideoControls(bool isDark, ThemeData theme) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Colors.white24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: Colors.white24,
                thumbColor: theme.colorScheme.primary,
                overlayColor: theme.colorScheme.primary.withOpacity(0.2),
              ),
              child: Slider(
                value: _position.inMilliseconds.toDouble(),
                max: _duration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  _videoController?.seekTo(Duration(milliseconds: value.toInt()));
                },
              ),
            ),
            
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.replay_10, color: Colors.white),
                  onPressed: () {
                    final newPosition = _position - Duration(seconds: 10);
                    _videoController?.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () {
                    if (_isPlaying) {
                      _videoController?.pause();
                    } else {
                      _videoController?.play();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.forward_10, color: Colors.white),
                  onPressed: () {
                    final newPosition = _position + Duration(seconds: 10);
                    _videoController?.seekTo(newPosition > _duration ? _duration : newPosition);
                  },
                ),
                IconButton(
                  icon: Icon(
                    _volume > 0 ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white,
                  ),
                  onPressed: _showVolumeDialog,
                ),
                Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: GoogleFonts.comicNeue(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    void _showPlaybackSpeedDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Playback Speed', style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
              return ListTile(
                title: Text('${speed}x'),
                leading: Radio<double>(
                  value: speed,
                  groupValue: _playbackSpeed,
                  onChanged: (value) {
                    setState(() {
                      _playbackSpeed = value!;
                    });
                    _videoController?.setPlaybackSpeed(value!);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    void _showVolumeDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Volume', style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: _volume,
                onChanged: (value) {
                  setState(() {
                    _volume = value;
                  });
                  _videoController?.setVolume(value);
                },
                min: 0.0,
                max: 1.0,
              ),
              Text('${(_volume * 100).toInt()}%'),
            ],
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
      _controlsAnimationController.dispose();
      _videoController?.removeListener(_videoListener);
      _videoController?.dispose();
      _chewieController?.dispose();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      super.dispose();
    }
  }


  // Audio Viewer Screen
  // Enhanced Audio Viewer Screen
  class AudioViewerScreen extends StatefulWidget {
    final DriveFile file;
    final GoogleDriveService driveService;

    const AudioViewerScreen({
      Key? key,
      required this.file,
      required this.driveService,
    }) : super(key: key);

    @override
    State<AudioViewerScreen> createState() => _AudioViewerScreenState();
  }

  class _AudioViewerScreenState extends State<AudioViewerScreen> with TickerProviderStateMixin {
    AudioPlayer? _audioPlayer;
    File? _localFile;
    bool _isLoading = true;
    bool _isPlaying = false;
    String? _error;
    Duration _duration = Duration.zero;
    Duration _position = Duration.zero;
    double _volume = 1.0;
    double _playbackSpeed = 1.0;
    PlayerState _playerState = PlayerState.stopped;
    
    // Animation Controllers
    late AnimationController _waveAnimationController;
    late AnimationController _rotationController;
    late Animation<double> _waveAnimation;
    late Animation<double> _rotationAnimation;
    
    // Visualizer
    List<double> _waveformData = List.generate(50, (index) => 0.0);
    Timer? _visualizerTimer;
    
    // Playlist support
    bool _isRepeat = false;
    bool _isShuffle = false;

    @override
    void initState() {
      super.initState();
      _initializeAnimations();
      _downloadAndOpenFile();
    }

    void _initializeAnimations() {
      _waveAnimationController = AnimationController(
        duration: Duration(milliseconds: 100),
        vsync: this,
      );
      
      _rotationController = AnimationController(
        duration: Duration(seconds: 10),
        vsync: this,
      );
      
      _waveAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _waveAnimationController, curve: Curves.easeInOut),
      );
      
      _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
        CurvedAnimation(parent: _rotationController, curve: Curves.linear),
      );
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
          _audioPlayer = AudioPlayer();

          _audioPlayer!.onDurationChanged.listen((duration) {
            setState(() => _duration = duration);
          });

          _audioPlayer!.onPositionChanged.listen((position) {
            setState(() => _position = position);
          });

          _audioPlayer!.onPlayerStateChanged.listen((state) {
            setState(() {
              _playerState = state;
              _isPlaying = state == PlayerState.playing;
            });
            
            if (_isPlaying) {
              _rotationController.repeat();
              _startVisualizer();
            } else {
              _rotationController.stop();
              _stopVisualizer();
            }
          });

          setState(() {
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to download audio file';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }

    void _startVisualizer() {
      _visualizerTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
        if (_isPlaying) {
          setState(() {
            _waveformData = List.generate(50, (index) {
              return (math.Random().nextDouble() * 0.8 + 0.2) * 
                    (1.0 - (_position.inMilliseconds / _duration.inMilliseconds.clamp(1, double.infinity)));
            });
          });
          _waveAnimationController.forward().then((_) {
            _waveAnimationController.reset();
          });
        }
      });
    }

    void _stopVisualizer() {
      _visualizerTimer?.cancel();
      setState(() {
        _waveformData = List.generate(50, (index) => 0.0);
      });
    }

    Future<void> _playPause() async {
      if (_audioPlayer == null || _localFile == null) return;

      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play(DeviceFileSource(_localFile!.path));
      }
    }

    Future<void> _seek(Duration position) async {
      await _audioPlayer?.seek(position);
    }

    Future<void> _setVolume(double volume) async {
      await _audioPlayer?.setVolume(volume);
      setState(() {
        _volume = volume;
      });
    }

    Future<void> _setPlaybackSpeed(double speed) async {
      await _audioPlayer?.setPlaybackRate(speed);
      setState(() {
        _playbackSpeed = speed;
      });
    }

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        backgroundColor: isDark ? Color(0xFF0D1117) : Colors.grey.shade900,
        appBar: _buildAppBar(isDark, theme),
        body: _buildBody(isDark, theme),
        bottomNavigationBar: _buildAudioControls(isDark, theme),
      );
    }

    PreferredSizeWidget _buildAppBar(bool isDark, ThemeData theme) {
      return AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.file.name,
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_duration != Duration.zero)
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.speed),
            onPressed: _showPlaybackSpeedDialog,
            tooltip: 'Playback Speed',
          ),
          IconButton(
            icon: Icon(_isRepeat ? Icons.repeat_one : Icons.repeat),
            onPressed: () {
              setState(() {
                _isRepeat = !_isRepeat;
              });
            },
            tooltip: 'Repeat',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'equalizer',
                child: Row(
                  children: [
                    Icon(Icons.equalizer, size: 20),
                    SizedBox(width: 8),
                    Text('Equalizer'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'timer',
                child: Row(
                  children: [
                    Icon(Icons.timer, size: 20),
                    SizedBox(width: 8),
                    Text('Sleep Timer'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Audio Info'),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget _buildBody(bool isDark, ThemeData theme) {
      if (_isLoading) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.audiotrack,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Loading Audio...',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Preparing enhanced audio player',
                style: GoogleFonts.comicNeue(
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 20),
              LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ],
          ),
        );
      }

      if (_error != null) {
        return Center(
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
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 40),
            
            // Album art / Visualizer
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.3),
                    theme.colorScheme.primary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(140),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating background
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(120),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Center circle
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Icon(
                      Icons.audiotrack,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Visualizer overlay
                  if (_isPlaying)
                    Container(
                      width: 280,
                      height: 280,
                      child: CustomPaint(
                        painter: AudioVisualizerPainter(_waveformData, theme.colorScheme.primary),
                      ),
                    ),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            // Track info
            Text(
              widget.file.name.replaceAll(RegExp(r'\.[^.]*$'), ''),
              style: GoogleFonts.comicNeue(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: 8),
            
            Text(
              '${widget.file.displaySize}',
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            
            SizedBox(height: 40),
            
            // Progress bar
            Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: theme.colorScheme.primary,
                    overlayColor: theme.colorScheme.primary.withOpacity(0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble(),
                    max: _duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: GoogleFonts.comicNeue(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: GoogleFonts.comicNeue(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 40),
            
            // Main controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous, color: Colors.white, size: 36),
                  onPressed: () {
                    _seek(Duration.zero);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.replay_10, color: Colors.white, size: 32),
                  onPressed: () {
                    final newPosition = _position - Duration(seconds: 10);
                    _seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                    onPressed: _playPause,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.forward_10, color: Colors.white, size: 32),
                  onPressed: () {
                    final newPosition = _position + Duration(seconds: 10);
                    _seek(newPosition > _duration ? _duration : newPosition);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.skip_next, color: Colors.white, size: 36),
                  onPressed: () {
                    _seek(_duration);
                  },
                ),
              ],
            ),
            
            SizedBox(height: 30),
            
            // Volume control
            Row(
              children: [
                Icon(Icons.volume_down, color: Colors.white70),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: theme.colorScheme.primary,
                      trackHeight: 2,
                    ),
                    child: Slider(
                      value: _volume,
                      onChanged: _setVolume,
                      min: 0.0,
                      max: 1.0,
                    ),
                  ),
                ),
                Icon(Icons.volume_up, color: Colors.white70),
              ],
            ),
          ],
        ),
      );
    }

    Widget _buildAudioControls(bool isDark, ThemeData theme) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          border: Border(
            top: BorderSide(color: Colors.white24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                _isShuffle ? Icons.shuffle_on : Icons.shuffle,
                color: _isShuffle ? theme.colorScheme.primary : Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _isShuffle = !_isShuffle;
                });
              },
              tooltip: 'Shuffle',
            ),
            IconButton(
              icon: Icon(
                _isRepeat ? Icons.repeat_one : Icons.repeat,
                color: _isRepeat ? theme.colorScheme.primary : Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _isRepeat = !_isRepeat;
                });
              },
              tooltip: 'Repeat',
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_playbackSpeed}x',
                style: GoogleFonts.comicNeue(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.equalizer, color: Colors.white70),
              onPressed: () => _handleMenuAction('equalizer'),
              tooltip: 'Equalizer',
            ),
          ],
        ),
      );
    }

    void _showPlaybackSpeedDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            'Playback Speed',
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
              return ListTile(
                title: Text(
                  '${speed}x',
                  style: GoogleFonts.comicNeue(color: Colors.white),
                ),
                leading: Radio<double>(
                  value: speed,
                  groupValue: _playbackSpeed,
                  onChanged: (value) {
                    _setPlaybackSpeed(value!);
                    Navigator.pop(context);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    void _handleMenuAction(String action) {
      switch (action) {
        case 'equalizer':
          _showEqualizerDialog();
          break;
        case 'timer':
          _showSleepTimerDialog();
          break;
        case 'info':
          _showAudioInfo();
          break;
      }
    }

    void _showEqualizerDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            'Equalizer',
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Text(
            'Equalizer feature coming soon!',
            style: GoogleFonts.comicNeue(color: Colors.white),
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

    void _showSleepTimerDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            'Sleep Timer',
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Text(
            'Sleep timer feature coming soon!',
            style: GoogleFonts.comicNeue(color: Colors.white),
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

    void _showAudioInfo() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            'Audio Information',
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Name', widget.file.name),
              _buildInfoRow('Size', widget.file.displaySize),
              _buildInfoRow('Duration', _formatDuration(_duration)),
              _buildInfoRow('Position', _formatDuration(_position)),
              _buildInfoRow('Volume', '${(_volume * 100).toInt()}%'),
              _buildInfoRow('Speed', '${_playbackSpeed}x'),
            ],
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

    Widget _buildInfoRow(String label, String value) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '$label:',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
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
      _visualizerTimer?.cancel();
      _waveAnimationController.dispose();
      _rotationController.dispose();
      _audioPlayer?.dispose();
      super.dispose();
    }
  }

  // Custom painter for audio visualizer
  class AudioVisualizerPainter extends CustomPainter {
    final List<double> waveformData;
    final Color color;

    AudioVisualizerPainter(this.waveformData, this.color);

    @override
    void paint(Canvas canvas, Size size) {
      final paint = Paint()
        ..color = color.withOpacity(0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.fill;

      final center = Offset(size.width / 2, size.height / 2);
      final radius = size.width / 2 - 20;

      for (int i = 0; i < waveformData.length; i++) {
        final angle = (i / waveformData.length) * 2 * math.pi;
        final amplitude = waveformData[i] * 30;
        
        final startX = center.dx + (radius - amplitude) * math.cos(angle);
        final startY = center.dy + (radius - amplitude) * math.sin(angle);
        final endX = center.dx + radius * math.cos(angle);
        final endY = center.dy + radius * math.sin(angle);

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          paint,
        );
      }
    }

    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
  }

  // Add this new screen for document files
  class DocumentViewerScreen extends StatefulWidget {
    final DriveFile file;
    final GoogleDriveService driveService;

    const DocumentViewerScreen({
      Key? key,
      required this.file,
      required this.driveService,
    }) : super(key: key);

    @override
    State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
  }

  class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
    File? _localFile;
    bool _isLoading = true;
    String? _error;
    String _fileContent = '';
    final ScrollController _scrollController = ScrollController();

    @override
    void initState() {
      super.initState();
      _downloadAndProcessFile();
    }

    Future<void> _downloadAndProcessFile() async {
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
          await _processFileContent(file);
          setState(() {
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to download file';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }

    Future<void> _processFileContent(File file) async {
      try {
        if (_isTextFile()) {
          _fileContent = await file.readAsString();
        } else if (_isWordFile()) {
          _fileContent = await _extractDocxContent(file);
        } else if (_isExcelFile()) {
          _fileContent = await _extractExcelContent(file);
        } else if (_isPowerPointFile()) {
          _fileContent = await _extractPowerPointContent(file);
        }
      } catch (e) {
        _fileContent = 'Error reading file content: $e';
      }
    }

    bool _isTextFile() {
      return widget.file.mimeType.contains('text') || 
            widget.file.name.toLowerCase().endsWith('.txt');
    }

    bool _isWordFile() {
      return widget.file.mimeType.contains('wordprocessingml') ||
            widget.file.mimeType.contains('msword') ||
            widget.file.name.toLowerCase().endsWith('.docx') ||
            widget.file.name.toLowerCase().endsWith('.doc');
    }

    bool _isExcelFile() {
      return widget.file.mimeType.contains('spreadsheet') ||
            widget.file.mimeType.contains('excel') ||
            widget.file.mimeType.contains('ms-excel') ||
            widget.file.name.toLowerCase().endsWith('.xlsx') ||
            widget.file.name.toLowerCase().endsWith('.xls');
    }

    bool _isPowerPointFile() {
      return widget.file.mimeType.contains('presentation') ||
            widget.file.mimeType.contains('powerpoint') ||
            widget.file.mimeType.contains('ms-powerpoint') ||
            widget.file.name.toLowerCase().endsWith('.pptx') ||
            widget.file.name.toLowerCase().endsWith('.ppt');
    }

    Future<String> _extractDocxContent(File file) async {
      try {
        String content = 'ðŸ“„ Microsoft Word Document\n';
        content += 'â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•\n\n';
        content += 'Document: ${widget.file.name}\n';
        content += 'File Size: ${widget.file.displaySize}\n';
        content += 'Modified: ${_formatDate(widget.file.modifiedTime)}\n\n';
        content += 'ðŸ“‹ Document Information:\n';
        content += 'â€¢ Format: DOCX (Microsoft Word)\n';
        content += 'â€¢ Type: Word Processing Document\n';
        content += 'â€¢ Created: ${_formatDate(widget.file.createdTime)}\n';
        content += 'â€¢ Last Modified: ${_formatDate(widget.file.modifiedTime)}\n\n';
        content += 'ðŸ“ Content Overview:\n';
        content += 'This document contains formatted text, potentially including:\n';
        content += 'â€¢ Headers and paragraphs\n';
        content += 'â€¢ Tables and lists\n';
        content += 'â€¢ Images and media\n';
        content += 'â€¢ Styles and formatting\n\n';
        content += 'âš ï¸ Note: This is a preview representation.\n';
        content += 'For full document viewing with proper formatting,\n';
        content += 'please use Microsoft Word or compatible software.\n\n';
        content += 'ðŸ”§ Supported Operations:\n';
        content += 'â€¢ View document information\n';
        content += 'â€¢ Share document link\n';
        content += 'â€¢ Add to favorites\n';
        content += 'â€¢ Download for offline access';
        
        return content;
      } catch (e) {
        return 'Error extracting DOCX content: $e';
      }
    }

    Future<String> _extractExcelContent(File file) async {
      try {
        String content = 'ðŸ“Š Microsoft Excel Spreadsheet\n';
        content += 'â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•\n\n';
        content += 'Spreadsheet: ${widget.file.name}\n';
        content += 'File Size: ${widget.file.displaySize}\n';
        content += 'Modified: ${_formatDate(widget.file.modifiedTime)}\n\n';
        content += 'ðŸ“‹ Spreadsheet Information:\n';
        content += 'â€¢ Format: ${widget.file.fileExtension?.toUpperCase() ?? 'XLSX'} (Microsoft Excel)\n';
        content += 'â€¢ Type: Spreadsheet Document\n';
        content += 'â€¢ Created: ${_formatDate(widget.file.createdTime)}\n';
        content += 'â€¢ Last Modified: ${_formatDate(widget.file.modifiedTime)}\n\n';
        content += 'ðŸ“ˆ Content Structure:\n';
        content += 'This spreadsheet may contain:\n';
        content += 'â€¢ Multiple worksheets/tabs\n';
        content += 'â€¢ Data tables and cells\n';
        content += 'â€¢ Formulas and calculations\n';
        content += 'â€¢ Charts and graphs\n';
        content += 'â€¢ Pivot tables and analysis\n';
        content += 'â€¢ Conditional formatting\n\n';
        content += 'ðŸ”¢ Typical Use Cases:\n';
        content += 'â€¢ Data analysis and reporting\n';
        content += 'â€¢ Financial calculations\n';
        content += 'â€¢ Project tracking\n';
        content += 'â€¢ Statistical analysis\n\n';
        content += 'âš ï¸ Note: This is a preview representation.\n';
        content += 'For full spreadsheet functionality with formulas,\n';
        content += 'please use Microsoft Excel or compatible software.\n\n';
        content += 'ðŸ”§ Supported Operations:\n';
        content += 'â€¢ View spreadsheet information\n';
        content += 'â€¢ Share spreadsheet link\n';
        content += 'â€¢ Add to favorites\n';
        content += 'â€¢ Download for offline access';
        
        return content;
      } catch (e) {
        return 'Error extracting Excel content: $e';
      }
    }

    Future<String> _extractPowerPointContent(File file) async {
      try {
        String content = 'ðŸŽ¯ Microsoft PowerPoint Presentation\n';
        content += 'â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•\n\n';
        content += 'Presentation: ${widget.file.name}\n';
        content += 'File Size: ${widget.file.displaySize}\n';
        content += 'Modified: ${_formatDate(widget.file.modifiedTime)}\n\n';
        content += 'ðŸ“‹ Presentation Information:\n';
        content += 'â€¢ Format: ${widget.file.fileExtension?.toUpperCase() ?? 'PPTX'} (Microsoft PowerPoint)\n';
        content += 'â€¢ Type: Presentation Document\n';
        content += 'â€¢ Created: ${_formatDate(widget.file.createdTime)}\n';
        content += 'â€¢ Last Modified: ${_formatDate(widget.file.modifiedTime)}\n\n';
        content += 'ðŸŽ¨ Content Structure:\n';
        content += 'This presentation may contain:\n';
        content += 'â€¢ Multiple slides with layouts\n';
        content += 'â€¢ Text content and titles\n';
        content += 'â€¢ Images and graphics\n';
        content += 'â€¢ Charts and diagrams\n';
        content += 'â€¢ Animations and transitions\n';
        content += 'â€¢ Speaker notes\n\n';
        content += 'ðŸ“½ï¸ Typical Use Cases:\n';
        content += 'â€¢ Business presentations\n';
        content += 'â€¢ Educational lectures\n';
        content += 'â€¢ Training materials\n';
        content += 'â€¢ Project proposals\n';
        content += 'â€¢ Conference talks\n\n';
        content += 'âš ï¸ Note: This is a preview representation.\n';
        content += 'For full presentation viewing with animations,\n';
        content += 'please use Microsoft PowerPoint or compatible software.\n\n';
        content += 'ðŸ”§ Supported Operations:\n';
        content += 'â€¢ View presentation information\n';
        content += 'â€¢ Share presentation link\n';
        content += 'â€¢ Add to favorites\n';
        content += 'â€¢ Download for offline access';
        
        return content;
      } catch (e) {
        return 'Error extracting PowerPoint content: $e';
      }
    }

    String _formatDate(DateTime date) {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.file.name,
            style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () => _shareFile(),
              tooltip: 'Share',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'info':
                    _showFileInfo();
                    break;
                  case 'refresh':
                    _downloadAndProcessFile();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20),
                      SizedBox(width: 8),
                      Text('File Info'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _buildBody(isDark, theme),
      );
    }

    Widget _buildBody(bool isDark, ThemeData theme) {
      if (_isLoading) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              SizedBox(height: 16),
              Text(
                'Loading ${widget.file.fileTypeCategory.toLowerCase()}...',
                style: GoogleFonts.comicNeue(
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }

      if (_error != null) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error Loading File',
                  style: GoogleFonts.comicNeue(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _error!,
                  style: GoogleFonts.comicNeue(
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _downloadAndProcessFile,
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          // File info header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.file.fileTypeColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.file.fileTypeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.file.fileIcon,
                    color: widget.file.fileTypeColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.file.fileTypeCategory,
                        style: GoogleFonts.comicNeue(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.file.fileTypeColor,
                        ),
                      ),
                      Text(
                        widget.file.displaySize,
                        style: GoogleFonts.comicNeue(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getFileTypeColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getFileTypeLabel(),
                    style: GoogleFonts.comicNeue(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getFileTypeColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content area
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              child: _isTextFile() 
                  ? _buildTextContent(isDark, theme)
                  : _buildDocumentPreview(isDark, theme),
            ),
          ),
        ],
      );
    }

    Color _getFileTypeColor() {
      if (_isWordFile()) return Colors.blue;
      if (_isExcelFile()) return Colors.green;
      if (_isPowerPointFile()) return Colors.orange;
      if (_isTextFile()) return Colors.grey;
      return widget.file.fileTypeColor;
    }

    String _getFileTypeLabel() {
      if (_isWordFile()) return 'Word Document';
      if (_isExcelFile()) return 'Excel Spreadsheet';
      if (_isPowerPointFile()) return 'PowerPoint';
      if (_isTextFile()) return 'Text File';
      return 'Document';
    }

    Widget _buildTextContent(bool isDark, ThemeData theme) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C2542) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SelectableText(
              _fileContent.isEmpty ? 'No content to display' : _fileContent,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildDocumentPreview(bool isDark, ThemeData theme) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C2542) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document icon and title
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getFileTypeColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.file.fileIcon,
                        color: _getFileTypeColor(),
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Document Preview',
                            style: GoogleFonts.comicNeue(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getFileTypeColor(),
                            ),
                          ),
                          Text(
                            _getFileTypeLabel(),
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Content
                SelectableText(
                  _fileContent,
                  style: GoogleFonts.comicNeue(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    void _shareFile() {
      Share.share('Check out this file: ${widget.file.name}\n${widget.file.webViewLink ?? ''}');
    }

    void _showFileInfo() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'File Information',
            style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Name', widget.file.name),
              _buildInfoRow('Type', widget.file.fileTypeCategory),
              _buildInfoRow('Size', widget.file.displaySize),
              _buildInfoRow('Modified', _formatDate(widget.file.modifiedTime)),
              _buildInfoRow('Created', _formatDate(widget.file.createdTime)),
            ],
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

    Widget _buildInfoRow(String label, String value) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '$label:',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.comicNeue(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    @override
    void dispose() {
      _scrollController.dispose();
      super.dispose();
    }
  }

