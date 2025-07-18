// office_viewers.dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jeezy/screens/notes_screen.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// Enhanced Office Document Viewer with real content display
class OfficeDocumentViewer extends StatefulWidget {
  final DriveFile file;
  final GoogleDriveService driveService;

  const OfficeDocumentViewer({
    Key? key,
    required this.file,
    required this.driveService,
  }) : super(key: key);

  @override
  State<OfficeDocumentViewer> createState() => _OfficeDocumentViewerState();
}

class _OfficeDocumentViewerState extends State<OfficeDocumentViewer> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isFullscreen = false;
  String? _error;
  File? _localFile;
  Map<String, dynamic>? _parsedContent;
  
  // Animation Controllers
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;
  
  // Document Navigation
  int _currentSlide = 0;
  int _currentSheet = 0;
  double _zoomLevel = 1.0;
  
  // Scroll Controllers
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeViewer();
  }

  void _initializeAnimations() {
    _loadingController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    _loadingController.repeat();
  }

  Future<void> _initializeViewer() async {
  try {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Download the original file with retry logic
    File? file;
    int retryCount = 0;
    const maxRetries = 3;
    
    while (file == null && retryCount < maxRetries) {
      try {
        file = await widget.driveService.downloadFile(
          widget.file.id,
          widget.file.name,
        );
        if (file != null) break;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception('Failed to download after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: retryCount)); // Exponential backoff
      }
    }

    if (file != null) {
      _localFile = file;
      
      // Validate file size
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Downloaded file is empty');
      }
      
      await _parseDocument(file);
      setState(() {
        _isLoading = false;
      });
      _loadingController.stop();
    } else {
      setState(() {
        _error = 'Failed to download file after multiple attempts';
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


  Future<void> _parseDocument(File file) async {
    try {
      if (_isWordFile()) {
        _parsedContent = await _parseDocxFile(file);
      } else if (_isExcelFile()) {
        _parsedContent = await _parseXlsxFile(file);
      } else if (_isPowerPointFile()) {
        _parsedContent = await _parsePptxFile(file);
      } else {
        _parsedContent = {'error': 'Unsupported file type'};
      }
      
      if (_parsedContent!.containsKey('error')) {
        setState(() {
          _error = _parsedContent!['error'];
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error parsing document: $e';
      });
    }
  }

  Future<Map<String, dynamic>> _parseDocxFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Find document.xml
      ArchiveFile? documentXml;
      for (final archiveFile in archive) {
        if (archiveFile.name == 'word/document.xml') {
          documentXml = archiveFile;
          break;
        }
      }
      
      if (documentXml == null) {
        return {'error': 'Invalid DOCX file - no document.xml found'};
      }
      
      final xmlContent = utf8.decode(documentXml.content as List<int>);
      final document = XmlDocument.parse(xmlContent);
      
      List<Map<String, dynamic>> paragraphs = [];
      List<Map<String, dynamic>> tables = [];
      
      // Parse paragraphs
      final paragraphNodes = document.findAllElements('w:p');
      for (final pNode in paragraphNodes) {
        final paragraph = _parseWordParagraph(pNode);
        if (paragraph['runs'].isNotEmpty) {
          paragraphs.add(paragraph);
        }
      }
      
      // Parse tables
      final tableNodes = document.findAllElements('w:tbl');
      for (final tblNode in tableNodes) {
        final table = _parseWordTable(tblNode);
        if (table['rows'].isNotEmpty) {
          tables.add(table);
        }
      }
      
      return {
        'type': 'docx',
        'paragraphs': paragraphs,
        'tables': tables,
        'title': widget.file.name,
      };
    } catch (e) {
      return {'error': 'Failed to parse DOCX: $e'};
    }
  }

  Map<String, dynamic> _parseWordParagraph(XmlElement pNode) {
    List<Map<String, dynamic>> runs = [];
    final runNodes = pNode.findAllElements('w:r');
    
    for (final rNode in runNodes) {
      final textNodes = rNode.findAllElements('w:t');
      if (textNodes.isNotEmpty) {
        String text = textNodes.map((t) => t.innerText).join();
        
        // Extract formatting
        final rPr = rNode.findElements('w:rPr').firstOrNull;
        Map<String, dynamic> formatting = {};
        
        if (rPr != null) {
          formatting['bold'] = rPr.findElements('w:b').isNotEmpty;
          formatting['italic'] = rPr.findElements('w:i').isNotEmpty;
          formatting['underline'] = rPr.findElements('w:u').isNotEmpty;
          
          final fontSize = rPr.findElements('w:sz').firstOrNull;
          if (fontSize != null) {
            formatting['fontSize'] = double.tryParse(fontSize.getAttribute('w:val') ?? '24') ?? 24;
          }
          
          final color = rPr.findElements('w:color').firstOrNull;
          if (color != null) {
            formatting['color'] = color.getAttribute('w:val') ?? '000000';
          }
        }
        
        runs.add({
          'text': text,
          'formatting': formatting,
        });
      }
    }
    
    return {
      'type': 'paragraph',
      'runs': runs,
    };
  }

  Map<String, dynamic> _parseWordTable(XmlElement tblNode) {
    List<List<String>> rows = [];
    final rowNodes = tblNode.findAllElements('w:tr');
    
    for (final trNode in rowNodes) {
      List<String> cells = [];
      final cellNodes = trNode.findAllElements('w:tc');
      
      for (final tcNode in cellNodes) {
        final textNodes = tcNode.findAllElements('w:t');
        final cellText = textNodes.map((t) => t.innerText).join(' ');
        cells.add(cellText);
      }
      
      if (cells.isNotEmpty) {
        rows.add(cells);
      }
    }
    
    return {
      'type': 'table',
      'rows': rows,
    };
  }

  Future<Map<String, dynamic>> _parsePptxFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      List<Map<String, dynamic>> slides = [];
      
      // Get slide files
      final slideFiles = archive.where((file) => 
          file.name.startsWith('ppt/slides/slide') && 
          file.name.endsWith('.xml')).toList();
      
      slideFiles.sort((a, b) => a.name.compareTo(b.name));
      
      for (int i = 0; i < slideFiles.length; i++) {
        final slideFile = slideFiles[i];
        final xmlContent = utf8.decode(slideFile.content as List<int>);
        final document = XmlDocument.parse(xmlContent);
        
        List<Map<String, dynamic>> textBoxes = [];
        String slideTitle = '';
        
        // Extract text from shapes
        final shapeNodes = document.findAllElements('p:sp');
        bool isFirstShape = true;
        
        for (final spNode in shapeNodes) {
          final textBody = spNode.findElements('p:txBody').firstOrNull;
          if (textBody != null) {
            final paragraphs = textBody.findAllElements('a:p');
            List<String> shapeTexts = [];
            
            for (final pNode in paragraphs) {
              final textNodes = pNode.findAllElements('a:t');
              if (textNodes.isNotEmpty) {
                final text = textNodes.map((t) => t.innerText).join(' ');
                if (text.trim().isNotEmpty) {
                  shapeTexts.add(text.trim());
                }
              }
            }
            
            if (shapeTexts.isNotEmpty) {
              final fullText = shapeTexts.join('\n');
              if (isFirstShape && slideTitle.isEmpty) {
                slideTitle = shapeTexts.first;
                isFirstShape = false;
              }
              
              textBoxes.add({
                'text': fullText,
                'isTitle': isFirstShape,
              });
            }
          }
        }
        
        slides.add({
          'slideNumber': i + 1,
          'title': slideTitle,
          'textBoxes': textBoxes,
        });
      }
      
      return {
        'type': 'pptx',
        'slides': slides,
        'title': widget.file.name,
      };
    } catch (e) {
      return {'error': 'Failed to parse PPTX: $e'};
    }
  }

  Future<Map<String, dynamic>> _parseXlsxFile(File file) async {
  try {
    final bytes = await file.readAsBytes();
    
    // Validate file size and structure
    if (bytes.length < 22) {
      return {'error': 'File too small to be a valid XLSX file'};
    }
    
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      // Try alternative parsing for corrupted files
      try {
        archive = ZipDecoder().decodeBytes(bytes, verify: false);
      } catch (e2) {
        return {'error': 'Invalid XLSX file format: Cannot extract ZIP archive'};
      }
    }
    
    // Verify it's a valid XLSX by checking for required files
    final requiredFiles = ['[Content_Types].xml', 'xl/workbook.xml'];
    for (final requiredFile in requiredFiles) {
      if (!archive.any((file) => file.name == requiredFile)) {
        return {'error': 'Invalid XLSX file: Missing required file $requiredFile'};
      }
    }
    
    // Parse shared strings with error handling
    Map<int, String> sharedStrings = {};
    try {
      final sharedStringsFile = archive.where(
        (file) => file.name == 'xl/sharedStrings.xml',
      ).firstOrNull;
      
      if (sharedStringsFile != null) {
        final sharedStringsXml = utf8.decode(sharedStringsFile.content as List<int>);
        final sharedStringsDoc = XmlDocument.parse(sharedStringsXml);
        final stringItems = sharedStringsDoc.findAllElements('si');
        
        int index = 0;
        for (final item in stringItems) {
          try {
            final textNodes = item.findAllElements('t');
            final text = textNodes.map((node) => node.innerText).join('');
            sharedStrings[index] = text;
            index++;
          } catch (e) {
            // Skip corrupted string entries
            sharedStrings[index] = '';
            index++;
          }
        }
      }
    } catch (e) {
      print('Warning: Could not parse shared strings: $e');
      // Continue without shared strings
    }
    
    // Parse worksheets with enhanced error handling
    List<Map<String, dynamic>> worksheets = [];
    try {
      final worksheetFiles = archive.where((file) => 
          file.name.startsWith('xl/worksheets/sheet') && 
          file.name.endsWith('.xml')).toList();
      
      if (worksheetFiles.isEmpty) {
        return {'error': 'No worksheets found in XLSX file'};
      }
      
      worksheetFiles.sort((a, b) => a.name.compareTo(b.name));
      
      for (int sheetIndex = 0; sheetIndex < worksheetFiles.length; sheetIndex++) {
        try {
          final worksheetFile = worksheetFiles[sheetIndex];
          final xmlContent = utf8.decode(worksheetFile.content as List<int>);
          final document = XmlDocument.parse(xmlContent);
          
          List<List<String>> rows = [];
          final rowNodes = document.findAllElements('row');
          
          // Limit rows to prevent memory issues
          final maxRows = 1000;
          int processedRows = 0;
          
          for (final rowNode in rowNodes) {
            if (processedRows >= maxRows) break;
            
            try {
              final cellNodes = rowNode.findAllElements('c');
              List<String> cellValues = [];
              
              // Limit columns to prevent overflow
              final maxCols = 50;
              int processedCols = 0;
              
              for (final cellNode in cellNodes) {
                if (processedCols >= maxCols) break;
                
                try {
                  final valueElement = cellNode.findElements('v').firstOrNull;
                  if (valueElement != null) {
                    final value = valueElement.innerText;
                    final cellType = cellNode.getAttribute('t');
                    
                    if (cellType == 's' && sharedStrings.isNotEmpty) {
                      final index = int.tryParse(value);
                      if (index != null && sharedStrings.containsKey(index)) {
                        cellValues.add(sharedStrings[index]!);
                      } else {
                        cellValues.add(value);
                      }
                    } else {
                      cellValues.add(value);
                    }
                  } else {
                    cellValues.add('');
                  }
                  processedCols++;
                } catch (e) {
                  // Skip corrupted cells
                  cellValues.add('');
                  processedCols++;
                }
              }
              
              if (cellValues.any((cell) => cell.isNotEmpty)) {
                // Ensure consistent column count
                while (cellValues.length < 10) {
                  cellValues.add('');
                }
                rows.add(cellValues.take(10).toList());
              }
              processedRows++;
            } catch (e) {
              // Skip corrupted rows
              continue;
            }
          }
          
          if (rows.isNotEmpty) {
            worksheets.add({
              'name': 'Sheet ${sheetIndex + 1}',
              'rows': rows,
            });
          }
        } catch (e) {
          print('Warning: Could not parse worksheet ${sheetIndex + 1}: $e');
          // Continue with other worksheets
        }
      }
    } catch (e) {
      return {'error': 'Failed to parse worksheets: $e'};
    }
    
    if (worksheets.isEmpty) {
      return {'error': 'No valid data found in XLSX file'};
    }
    
    return {
      'type': 'xlsx',
      'worksheets': worksheets,
      'title': widget.file.name,
    };
  } catch (e) {
    return {'error': 'Failed to parse XLSX: $e'};
  }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isFullscreen) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isDark, theme),
      body: Container(
        color: Colors.black,
        child: _buildDocumentContent(isDark, theme),
      ),
    );
  }

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0D1117) : Colors.grey.shade50,
      appBar: _buildAppBar(isDark, theme),
      body: _buildBody(isDark, theme),
      bottomNavigationBar: _buildBottomControls(isDark, theme),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, ThemeData theme) {
  if (_isFullscreen) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      automaticallyImplyLeading: false, // Remove default back button
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(Icons.fullscreen_exit, color: Colors.white),
          onPressed: () {
            setState(() {
              _isFullscreen = false;
            });
          },
          tooltip: 'Exit Fullscreen',
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showFileInfo,
            tooltip: 'File Info',
          ),
        ),
      ],
    );
  }

  return AppBar(
    backgroundColor: isDark ? Color(0xFF161B22) : Colors.white,
    foregroundColor: isDark ? Colors.white : Colors.black,
    elevation: 0,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.file.name,
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (_parsedContent != null)
          Text(
            _getDocumentInfo(),
            style: GoogleFonts.comicNeue(
              fontSize: 12,
              color: theme.colorScheme.primary,
            ),
          ),
      ],
    ),
    actions: [
      if (!_isLoading && _parsedContent != null) ...[
        // Only fullscreen toggle
        IconButton(
          icon: Icon(Icons.fullscreen),
          onPressed: () {
            setState(() {
              _isFullscreen = true;
            });
          },
          tooltip: 'Fullscreen',
        ),
      ],
      PopupMenuButton<String>(
        onSelected: _handleMenuAction,
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
          PopupMenuItem(
            value: 'copy',
            child: Row(
              children: [
                Icon(Icons.copy, size: 20),
                SizedBox(width: 8),
                Text('Copy Text'),
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
      return _buildLoadingState(isDark, theme);
    }

    if (_error != null) {
      return _buildErrorState(isDark, theme);
    }

    if (_parsedContent == null) {
      return _buildEmptyState(isDark, theme);
    }

    return Transform.scale(
      scale: _zoomLevel,
      child: Container(
        width: MediaQuery.of(context).size.width / _zoomLevel,
        child: _buildDocumentContent(isDark, theme),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _loadingAnimation,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.file.fileTypeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.file.fileIcon,
                size: 64,
                color: widget.file.fileTypeColor,
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading ${widget.file.fileTypeCategory}...',
            style: GoogleFonts.comicNeue(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Parsing document content with formatting',
            style: GoogleFonts.comicNeue(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 20),
          LinearProgressIndicator(
            backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Unable to Parse Document',
              style: GoogleFonts.comicNeue(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeViewer,
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

  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No content found',
            style: GoogleFonts.comicNeue(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentContent(bool isDark, ThemeData theme) {
    switch (_parsedContent!['type']) {
      case 'docx':
        return _buildWordDocument(isDark, theme);
      case 'pptx':
        return _buildPowerPointDocument(isDark, theme);
      case 'xlsx':
        return _buildExcelDocument(isDark, theme);
      default:
        return _buildEmptyState(isDark, theme);
    }
  }

  Widget _buildWordDocument(bool isDark, ThemeData theme) {
  final paragraphs = _parsedContent!['paragraphs'] as List<Map<String, dynamic>>;
  final tables = _parsedContent!['tables'] as List<Map<String, dynamic>>;
  
  return Container(
    color: Colors.white,
    child: InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      boundaryMargin: EdgeInsets.all(20),
      constrained: true, // Changed to true for fit-to-screen
      alignment: Alignment.center, // Center alignment
      child: Center( // Additional centering wrapper
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          padding: EdgeInsets.all(24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9, // Responsive width
            constraints: BoxConstraints(
              maxWidth: 800,
              minWidth: 300,
            ),
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document title
                Container(
                  padding: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.description, color: Colors.blue, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.file.name,
                          style: GoogleFonts.comicNeue(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Document content with fixed sizing
                ...paragraphs.map((paragraph) => _buildWordParagraphWidget(paragraph)),
                ...tables.map((table) => _buildWordTableWidget(table)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}



  Widget _buildWordParagraphWidget(Map<String, dynamic> paragraph) {
  final runs = paragraph['runs'] as List<Map<String, dynamic>>;
  
  return Container(
    margin: EdgeInsets.only(bottom: 16),
    child: RichText(
      text: TextSpan(
        children: runs.map((run) {
          final formatting = run['formatting'] as Map<String, dynamic>? ?? {};
          
          return TextSpan(
            text: run['text'],
            style: GoogleFonts.comicNeue(
              fontSize: (formatting['fontSize'] ?? 24) / 2, // Fixed size
              fontWeight: formatting['bold'] == true ? FontWeight.bold : FontWeight.normal,
              fontStyle: formatting['italic'] == true ? FontStyle.italic : FontStyle.normal,
              decoration: formatting['underline'] == true ? TextDecoration.underline : TextDecoration.none,
              color: _parseColor(formatting['color'] ?? '000000'),
              height: 1.6,
            ),
          );
        }).toList(),
      ),
    ),
  );
}

Widget _buildWordTableWidget(Map<String, dynamic> table) {
  final rows = table['rows'] as List<List<String>>;
  
  return Container(
    margin: EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: rows.map((row) {
        return TableRow(
          children: row.map((cell) {
            return Container(
              padding: EdgeInsets.all(12), // Fixed padding
              child: Text(
                cell,
                style: GoogleFonts.comicNeue(
                  fontSize: 14, // Fixed font size
                  color: Colors.black87,
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    ),
  );
}



  Widget _buildPowerPointDocument(bool isDark, ThemeData theme) {
  final slides = _parsedContent!['slides'] as List<Map<String, dynamic>>;
  
  if (slides.isEmpty) {
    return _buildEmptyState(isDark, theme);
  }

  final currentSlideData = slides[_currentSlide];
  
  return Container(
    color: isDark ? Color(0xFF0D1117) : Colors.grey.shade100,
    child: Column(
      children: [
        // Slide navigation header - Fixed height
        Container(
          height: 80,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF161B22) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.slideshow, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PowerPoint Presentation',
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Slide ${_currentSlide + 1} of ${slides.length}',
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Slide thumbnails - Constrained
              if (slides.length > 1)
                Container(
                  height: 40,
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: slides.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentSlide = index;
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 40,
                          margin: EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: index == _currentSlide 
                                ? theme.colorScheme.primary.withOpacity(0.2)
                                : isDark ? Color(0xFF1C2542) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: index == _currentSlide 
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.comicNeue(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: index == _currentSlide 
                                    ? theme.colorScheme.primary
                                    : (isDark ? Colors.white70 : Colors.grey.shade600),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        
        // Current slide with pinch-to-zoom only
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            boundaryMargin: EdgeInsets.all(20),
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Slide title - Fixed size
                      if (currentSlideData['title'].toString().isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(bottom: 20),
                          child: Text(
                            currentSlideData['title'],
                            style: GoogleFonts.comicNeue(
                              fontSize: 24, // Fixed size
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      
                      // Slide content - Fixed sizes
                      ...((currentSlideData['textBoxes'] as List<Map<String, dynamic>>).map((textBox) {
                        return Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            textBox['text'],
                            style: GoogleFonts.comicNeue(
                              fontSize: textBox['isTitle'] == true ? 18 : 14, // Fixed sizes
                              fontWeight: textBox['isTitle'] == true ? FontWeight.bold : FontWeight.normal,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        );
                      })),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildExcelDocument(bool isDark, ThemeData theme) {
    final worksheets = _parsedContent!['worksheets'] as List<Map<String, dynamic>>;
    
    if (worksheets.isEmpty) {
      return _buildEmptyState(isDark, theme);
    }

    final currentWorksheet = worksheets[_currentSheet];
    final rows = currentWorksheet['rows'] as List<List<String>>;
    
    return Column(
      children: [
        // Sheet navigation
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF161B22) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.table_chart, color: Colors.green, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Excel Spreadsheet',
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      currentWorksheet['name'],
                      style: GoogleFonts.comicNeue(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Sheet tabs
              if (worksheets.length > 1)
                Container(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: worksheets.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentSheet = index;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: index == _currentSheet 
                                ? theme.colorScheme.primary.withOpacity(0.2)
                                : isDark ? Color(0xFF1C2542) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: index == _currentSheet 
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            worksheets[index]['name'],
                            style: GoogleFonts.comicNeue(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: index == _currentSheet 
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.white70 : Colors.grey.shade600),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        
        // Spreadsheet content
        Expanded(
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Scrollbar(
              controller: _horizontalScrollController,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: Scrollbar(
                  controller: _verticalScrollController,
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    child: _buildExcelTable(rows),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExcelTable(List<List<String>> rows) {
  if (rows.isEmpty) return Container();
  
  // Calculate max columns but limit to prevent overflow
  int maxColumns = rows.map((row) => row.length).reduce((a, b) => a > b ? a : b);
  maxColumns = maxColumns.clamp(1, 10); // Limit to 10 columns max
  
  return LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;
      final columnWidth = (availableWidth - 60) / maxColumns; // 60 for row number column
      
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: availableWidth,
          ),
          child: DataTable(
            headingRowHeight: 40,
            dataRowHeight: 35,
            columnSpacing: 8, // Reduced spacing
            horizontalMargin: 8,
            columns: [
              // Row number column
              DataColumn(
                label: Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '#',
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              // Data columns
              ...List.generate(maxColumns, (index) {
                return DataColumn(
                  label: Container(
                    width: columnWidth.clamp(60.0, 120.0), // Constrain column width
                    alignment: Alignment.center,
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, etc.
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ),
                );
              }),
            ],
            rows: rows.take(100).map((row) { // Limit to 100 rows
              final rowIndex = rows.indexOf(row);
              
              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (rowIndex % 2 == 0) {
                      return Colors.grey.withOpacity(0.1);
                    }
                    return null;
                  },
                ),
                cells: [
                  // Row number cell
                  DataCell(
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '${rowIndex + 1}',
                        style: GoogleFonts.comicNeue(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                  // Data cells
                  ...List.generate(maxColumns, (colIndex) {
                    final cellValue = colIndex < row.length ? row[colIndex] : '';
                    return DataCell(
                      Container(
                        width: columnWidth.clamp(60.0, 120.0),
                        child: Text(
                          cellValue.length > 20 ? '${cellValue.substring(0, 20)}...' : cellValue,
                          style: GoogleFonts.comicNeue(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}


  Widget? _buildBottomControls(bool isDark, ThemeData theme) {
    if (_parsedContent == null) return null;
    
    if (_parsedContent!['type'] == 'pptx') {
      final slides = _parsedContent!['slides'] as List<Map<String, dynamic>>;
      
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF161B22) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.skip_previous),
              onPressed: _currentSlide > 0 ? () {
                setState(() {
                  _currentSlide--;
                });
              } : null,
            ),
            Text(
              'Slide ${_currentSlide + 1} of ${slides.length}',
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.skip_next),
              onPressed: _currentSlide < slides.length - 1 ? () {
                setState(() {
                  _currentSlide++;
                });
              } : null,
            ),
          ],
        ),
      );
    }
    
    return null;
  }

  String _getDocumentInfo() {
    if (_parsedContent == null) return '';
    
    switch (_parsedContent!['type']) {
      case 'docx':
        final paragraphs = _parsedContent!['paragraphs'] as List;
        final tables = _parsedContent!['tables'] as List;
        return '${paragraphs.length} paragraphs, ${tables.length} tables';
      case 'pptx':
        final slides = _parsedContent!['slides'] as List;
        return '${slides.length} slides';
      case 'xlsx':
        final worksheets = _parsedContent!['worksheets'] as List;
        return '${worksheets.length} worksheets';
      default:
        return '';
    }
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse('FF$colorHex', radix: 16));
    } catch (e) {
      return Colors.black;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'info':
        _showFileInfo();
        break;
      case 'refresh':
        _initializeViewer();
        break;
      case 'copy':
        _copyDocumentText();
        break;
    }
  }

  void _shareFile() {
    Share.share('Check out this ${widget.file.fileTypeCategory}: ${widget.file.name}');
  }

  void _showFileInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Document Information',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', widget.file.name),
            _buildInfoRow('Type', widget.file.fileTypeCategory),
            _buildInfoRow('Size', widget.file.displaySize),
            _buildInfoRow('Content', _getDocumentInfo()),
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

  void _copyDocumentText() {
    String text = '';
    
    if (_parsedContent!['type'] == 'docx') {
      final paragraphs = _parsedContent!['paragraphs'] as List<Map<String, dynamic>>;
      for (final paragraph in paragraphs) {
        final runs = paragraph['runs'] as List<Map<String, dynamic>>;
        for (final run in runs) {
          text += run['text'];
        }
        text += '\n';
      }
    } else if (_parsedContent!['type'] == 'pptx') {
      final slides = _parsedContent!['slides'] as List<Map<String, dynamic>>;
      for (final slide in slides) {
        text += 'Slide ${slide['slideNumber']}:\n';
        final textBoxes = slide['textBoxes'] as List<Map<String, dynamic>>;
        for (final textBox in textBoxes) {
          text += '${textBox['text']}\n';
        }
        text += '\n';
      }
    } else if (_parsedContent!['type'] == 'xlsx') {
      final worksheets = _parsedContent!['worksheets'] as List<Map<String, dynamic>>;
      for (final worksheet in worksheets) {
        text += '${worksheet['name']}:\n';
        final rows = worksheet['rows'] as List<List<String>>;
        for (final row in rows) {
          text += '${row.join('\t')}\n';
        }
        text += '\n';
      }
    }
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document text copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }
}

// Enhanced Text Document Viewer
class TextDocumentViewer extends StatefulWidget {
  final DriveFile file;
  final GoogleDriveService driveService;

  const TextDocumentViewer({
    Key? key,
    required this.file,
    required this.driveService,
  }) : super(key: key);

  @override
  State<TextDocumentViewer> createState() => _TextDocumentViewerState();
}

class _TextDocumentViewerState extends State<TextDocumentViewer> {
  File? _localFile;
  bool _isLoading = true;
  String? _error;
  String _fileContent = '';
  final ScrollController _scrollController = ScrollController();
  double _fontSize = 14.0;
  bool _wordWrap = true;

  @override
  void initState() {
    super.initState();
    _loadTextFile();
  }

  Future<void> _loadTextFile() async {
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
        _fileContent = await file.readAsString();
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
            icon: Icon(Icons.text_decrease),
            onPressed: () {
              setState(() {
                _fontSize = (_fontSize - 1).clamp(10.0, 24.0);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.text_increase),
            onPressed: () {
              setState(() {
                _fontSize = (_fontSize + 1).clamp(10.0, 24.0);
              });
            },
          ),
          IconButton(
            icon: Icon(_wordWrap ? Icons.wrap_text : Icons.notes),
            onPressed: () {
              setState(() {
                _wordWrap = !_wordWrap;
              });
            },
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
              'Loading text file...',
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!, style: GoogleFonts.comicNeue(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTextFile,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // File info header
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.description, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Text Document • ${widget.file.displaySize} • ${_fileContent.split('\n').length} lines',
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ),
              Text(
                'Font: ${_fontSize.toInt()}px',
                style: GoogleFonts.comicNeue(
                  fontSize: 10,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: SelectableText(
                  _fileContent.isEmpty ? 'File is empty' : _fileContent,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: _fontSize,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  textAlign: _wordWrap ? TextAlign.left : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
