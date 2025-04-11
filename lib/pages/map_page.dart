import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';

class MapPage extends StatefulWidget {
  MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  _MapPageState();
  late MapShapeSource _shapeSource;
  late MapShapeSource _sublayerSource;
  late List<_DataModel> _data;
  int _selectedIndex = -1;
  int _selectedSublayerIndex = -1;
  late MapZoomPanBehavior _zoomPanBehavior;
  bool _isLoading = true;
  late FloatingSearchBarController _searchBarController;
  String _searchTerm = '';

  // Modified bottom sheet variables
  bool _isBottomSheetExpanded = false;
  double _bottomSheetHeight = 120.0; // Changed back to 120.0 as default
  _DataModel? _selectedLocation;

  // Quezon province default data
  final _quezonProvince = _DataModel('Quezon Province', 14.2347, 121.9473);

  // Tab controller for bottom sheet tabs
  late TabController _tabController;

  // Add new state variable for filter selection
  String _selectedFilter = 'General'; // Default selected filter

  // Add a state variable to track search bar open state
  bool _isSearchBarOpen = false;

  List<_DataModel> _generateDataModel() {
    return <_DataModel>[
      _DataModel('Agdangan', 13.885378, 121.9359),
      _DataModel('Alabat', 14.1017, 122.0184),
      _DataModel('Atimonan', 14.0048, 121.9199),
      _DataModel('Buenavista', 13.7087, 122.4635),
      _DataModel('Burdeos', 14.7446, 121.9262),
      _DataModel('Calauag', 13.9547, 122.2872),
      _DataModel('Candelaria', 13.9311, 121.4233),
      _DataModel('Catanauan', 13.5927, 122.3208),
      _DataModel('Dolores', 14.0244, 121.3681),
      _DataModel('General Luna', 13.8425, 122.1494),
      _DataModel('General Nakar', 14.7631, 121.6349),
      _DataModel('Guinayangan', 13.9039, 122.4467),
      _DataModel('Gumaca', 13.9208, 122.1000),
      _DataModel('Infanta', 14.7425, 121.6494),
      _DataModel('Jomalig', 14.7131, 122.3677),
      _DataModel('Lopez', 13.8881, 122.2608),
      _DataModel('Lucban', 14.1114, 121.5575),
      _DataModel('Lucena City', 13.9419, 121.6169),
      _DataModel('Macalelon', 13.7458, 122.1294),
      _DataModel('Mauban', 14.1911, 121.7308),
      _DataModel('Mulanay', 13.5264, 122.4044),
      _DataModel('Padre Burgos', 13.9222, 121.8125),
      _DataModel('Pagbilao', 13.9789, 121.7119),
      _DataModel('Panukulan', 14.7472, 121.8139),
      _DataModel('Patnanungan', 14.7481, 122.1736),
      _DataModel('Perez', 14.1944, 121.9394),
      _DataModel('Pitogo', 13.7972, 122.0936),
      _DataModel('Plaridel', 13.9392, 122.0212),
      _DataModel('Polillo', 14.7111, 121.9556),
      _DataModel('Quezon', 14.0314, 122.1131),
      _DataModel('Real', 14.6647, 121.6081),
      _DataModel('Sampaloc', 14.1774, 121.6169),
      _DataModel('San Andres', 13.3252, 122.6504),
      _DataModel('San Antonio', 13.8951, 121.2970),
      _DataModel('San Francisco', 13.3471, 122.5202),
      _DataModel('San Narciso', 13.5689, 122.5662),
      _DataModel('Sariaya', 13.9633, 121.5253),
      _DataModel('Tagkawayan', 13.9647, 122.5472),
      _DataModel('Tayabas City', 14.0244, 121.5847),
      _DataModel('Tiaong', 13.9500, 121.3167),
      _DataModel('Unisan', 13.8558, 121.9686),
    ];
  }

  @override
  void initState() {
    _searchBarController = FloatingSearchBarController();
    _zoomPanBehavior = MapZoomPanBehavior(
      enablePanning: true,
      enablePinching: true,
      enableDoubleTapZooming: true,
      zoomLevel: 5, // Increased initial zoom level
      minZoomLevel: 1,
      maxZoomLevel: 10,
      focalLatLng: MapLatLng(14.2347, 121.9473), // Centered on Quezon province
    );

    // Initialize tab controller with 3 tabs
    _tabController = TabController(length: 3, vsync: this);

    super.initState();
    _data = _generateDataModel();
    _shapeSource = MapShapeSource.asset(
      'lib/map/PHGeoJSON.json',
      shapeDataField: 'NAME_2',
      dataCount: _data.length,
      primaryValueMapper: (int index) => _data[index].name,
    );
    _sublayerSource = MapShapeSource.asset(
      'lib/map/GeoJSON.json',
      shapeDataField: 'NAME_2',
      dataCount: _data.length,
      primaryValueMapper: (int index) => _data[index].name,
    );
    debugPrint('MapShapeSource initialized');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchBarController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<_DataModel> _getFilteredList() {
    if (_searchTerm.isEmpty) return [];
    return _data
        .where((item) =>
            item.name.toLowerCase().contains(_searchTerm.toLowerCase()))
        .toList();
  }

  void _selectMunicity(_DataModel selected) {
    final index = _data.indexWhere((item) => item.name == selected.name);
    if (index != -1) {
      _zoomPanBehavior.focalLatLng =
          MapLatLng(selected.latitude, selected.longitude);
      _zoomPanBehavior.zoomLevel = 9;
      setState(() {
        _selectedSublayerIndex = index;
        _selectedLocation = selected;
        _isBottomSheetExpanded = false;
        _bottomSheetHeight = 120.0;
      });
    }
    _searchBarController.close();
  }

  void _handleEnterPress() {
    final filteredList = _getFilteredList();
    if (filteredList.isNotEmpty) {
      _selectMunicity(filteredList.first);
    }
  }

  void _handleSearch(String query) {
    final filteredList = _getFilteredList();
    if (filteredList.isNotEmpty) {
      _selectMunicity(filteredList.first);
    }
  }

  void _toggleBottomSheetExpansion() {
    setState(() {
      _isBottomSheetExpanded = !_isBottomSheetExpanded;
      _bottomSheetHeight = _isBottomSheetExpanded
          ? 700.0
          : 120.0; // Increased expanded height from 350 to 500
    });
  }

  // Add method to handle drag gesture on bottom sheet
  void _handleDragUpdate(DragUpdateDetails details) {
    // Negative delta.dy means upward drag, positive means downward drag
    if (details.delta.dy < -5 && !_isBottomSheetExpanded) {
      // Expand when dragging up
      _toggleBottomSheetExpansion();
    } else if (details.delta.dy > 5 && _isBottomSheetExpanded) {
      // Collapse when dragging down
      _toggleBottomSheetExpansion();
    }
  }

  void _resetToQuezonProvince() {
    setState(() {
      _selectedLocation = null;
      _selectedSublayerIndex = -1;
      _isBottomSheetExpanded = false;
      _bottomSheetHeight = 120.0;

      // Reset map view to Quezon province
      _zoomPanBehavior.focalLatLng =
          MapLatLng(_quezonProvince.latitude, _quezonProvince.longitude);
      _zoomPanBehavior.zoomLevel = 5;
    });
  }

  // Add method to handle filter selection
  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    // Here you would add logic to filter map data based on selected category
  }

  // Create widget for filter buttons with improved positioning and no splash
  Widget _buildFilterChips() {
    // If search bar is open, don't show the filter chips
    if (_isSearchBarOpen) return const SizedBox.shrink();

    // Define all filter options
    final List<String> filters = [
      'General',
      'Healthcare',
      'Social',
      'Education'
    ];

    return Positioned(
      top: 120, // Position precisely below search bar
      left: 0,
      right: 0,
      child: Container(
        height: 32,
        alignment: Alignment.centerLeft, // Align to left side
        child: ListView(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16), // Left padding only
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Theme(
                data: ThemeData(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  // Disable any shadow or elevation
                  chipTheme: ChipThemeData(
                    elevation: 0,
                    pressElevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
                child: RawChip(
                  // Use RawChip for more control
                  label: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => _onFilterSelected(filter),
                  backgroundColor: Colors.blue
                      .shade50, // Changed from shade100 to shade50 for lighter blue
                  selectedColor: Colors.blue.shade600,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0, // No elevation
                  pressElevation: 0, // No elevation when pressed
                  shadowColor: Colors.transparent, // No shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none, // No border
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    // Get the location to display - either selected location or default Quezon province
    final displayLocation = _selectedLocation ?? _quezonProvince;
    final bool isDefaultView = _selectedLocation == null;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: 0,
      left: 0,
      right: 0,
      height: _bottomSheetHeight,
      child: GestureDetector(
        onVerticalDragUpdate: _handleDragUpdate,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed-size drag handle area with consistent spacing
              Container(
                width: double.infinity,
                height: 16,
                alignment: Alignment.center,
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // Location header with fixed height and spacing
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                height: 50, // Fixed height for header area
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayLocation.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          isDefaultView
                              ? const Text(
                                  'Explore municipalities and cities',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                )
                              : Text(
                                  'Lat: ${displayLocation.latitude.toStringAsFixed(4)}, Long: ${displayLocation.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    if (!isDefaultView)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _resetToQuezonProvince,
                      ),
                  ],
                ),
              ),

              // Divider for consistent visual separation
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

              // Show different content based on whether we're showing Quezon Province or a specific municipality
              if (isDefaultView) // Only show tabs for Quezon Province
                Expanded(
                  child: Column(
                    children: [
                      // Tab Bar with fixed height
                      Container(
                        height: 40, // Fixed height for tab bar
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.blue,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blue,
                          labelStyle: const TextStyle(fontSize: 14),
                          indicatorWeight: 2.0,
                          tabs: const [
                            Tab(text: 'Data Analysis'),
                            Tab(text: 'Data Summary'),
                            Tab(text: 'Insights'),
                          ],
                        ),
                      ),

                      // Tab content with consistent padding
                      if (_isBottomSheetExpanded)
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildDataAnalysisTab(
                                  displayLocation, isDefaultView),
                              _buildDataSummaryTab(
                                  displayLocation, isDefaultView),
                              _buildInsightsTab(displayLocation, isDefaultView),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
              else // For municipalities, show a simpler layout
                _isBottomSheetExpanded
                    ? Expanded(
                        child: _buildMunicipalityContent(displayLocation),
                      )
                    : const SizedBox
                        .shrink(), // No additional content when collapsed for municipalities
            ],
          ),
        ),
      ),
    );
  }

  // New method to build municipality-specific content without tabs
  Widget _buildMunicipalityContent(_DataModel location) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Municipality info section
          Text(
            'About ${location.name}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Information about this municipality is currently being compiled. Here is what we know so far:',
          ),
          const SizedBox(height: 16),

          // Municipality data
          _buildMunicipalityDataSummary(location),

          const SizedBox(height: 24),

          // Additional sections can be added here for municipality-specific information
          const Text(
            'Geographic Features',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
              '${location.name} is located at coordinates ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)} within Quezon Province.'),

          const SizedBox(height: 24),
          const Text(
            'Local Economy',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Data on local economic activities will be added soon.'),
        ],
      ),
    );
  }

  Widget _buildDataAnalysisTab(_DataModel location, bool isDefaultView) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Analysis',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          isDefaultView
              ? const Text(
                  'Statistical analysis for Quezon Province showing demographic trends, '
                  'economic indicators, and geographical data distributions.')
              : Text(
                  'Analysis for ${location.name} showing key metrics and comparative data '
                  'with other municipalities in Quezon Province.'),
          const SizedBox(height: 16),
          // Placeholder for charts or data visualizations
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Chart: Population Trends for ${location.name}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSummaryTab(_DataModel location, bool isDefaultView) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          isDefaultView
              ? _buildProvinceDataSummary()
              : _buildMunicipalityDataSummary(location),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProvinceDataSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRow('Total Area', '8,706.60 km²'),
        _buildDataRow('Population (2020)', '1,950,459'),
        _buildDataRow('Population Density', '224/km²'),
        _buildDataRow('Number of Municipalities', '39'),
        _buildDataRow('Number of Cities', '2'),
        _buildDataRow('Capital', 'Lucena City'),
        _buildDataRow('Regional Classification', 'CALABARZON (Region IV-A)'),
      ],
    );
  }

  Widget _buildMunicipalityDataSummary(_DataModel location) {
    // This would ideally be filled with real data specific to each municipality
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRow('Municipality/City', location.name),
        _buildDataRow('Geographic Position',
            '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
        _buildDataRow('Land Area', 'Data not available'),
        _buildDataRow('Population', 'Data not available'),
        _buildDataRow('Barangays', 'Data not available'),
        _buildDataRow('Classification', 'Data not available'),
        _buildDataRow('Main Industry', 'Data not available'),
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(_DataModel location, bool isDefaultView) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insights',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          isDefaultView
              ? const Text(
                  'Quezon Province is known for its agricultural production, particularly coconut. '
                  'The province faces challenges such as development disparities between coastal and inland areas, '
                  'vulnerability to typhoons, and managing its natural resources sustainably.')
              : Text(
                  'Insights for ${location.name} will be displayed here, including '
                  'local economic opportunities, development challenges, and unique characteristics.'),
          const SizedBox(height: 16),
          const Text(
            'Key Observations:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildInsightPoint('1. Economic Potential',
              'Tourism and agriculture present significant growth opportunities.'),
          _buildInsightPoint('2. Development Challenges',
              'Infrastructure gaps and climate vulnerability need addressing.'),
          _buildInsightPoint('3. Recommendations',
              'Focus on sustainable development and economic diversification.'),
        ],
      ),
    );
  }

  Widget _buildInsightPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(description),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MapPage with selectedIndex: $_selectedIndex');
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SfMaps(
              layers: [
                MapShapeLayer(
                  loadingBuilder: (BuildContext context) {
                    return const Center(
                      child: SizedBox(
                        height: 25,
                        width: 25,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  },
                  source: _shapeSource,
                  color: const Color.fromARGB(
                      255, 218, 216, 216), // Set the color to blue
                  strokeColor: Colors.white, // Set the stroke color to white
                  strokeWidth: 1,
                  selectedIndex: _selectedIndex,
                  selectionSettings: const MapSelectionSettings(
                      color: Color.fromRGBO(87, 247, 212, 1),
                      strokeColor: Colors.white,
                      strokeWidth: 1),
                  zoomPanBehavior: _zoomPanBehavior,
                  onSelectionChanged: (int index) {
                    setState(() {
                      if (index != _selectedIndex) {
                        _selectedIndex = -1;
                        _selectedIndex = index;
                      } else {
                        _selectedIndex = -1;
                      }
                    });
                  },
                  sublayers: [
                    MapShapeSublayer(
                      source: _sublayerSource,
                      color: const Color.fromARGB(
                          255, 156, 156, 156), // Solid red default color
                      strokeColor: const Color.fromARGB(255, 201, 201, 201),
                      strokeWidth: 1,
                      selectedIndex: _selectedSublayerIndex,
                      selectionSettings: const MapSelectionSettings(
                          color: Color.fromARGB(255, 116, 92, 255),
                          strokeColor: Color.fromARGB(255, 0, 0, 0),
                          strokeWidth: 1),
                      onSelectionChanged: (int index) {
                        _zoomPanBehavior.focalLatLng = MapLatLng(
                            _data[index].latitude, _data[index].longitude);
                        _zoomPanBehavior.zoomLevel = 9;

                        setState(() {
                          if (index != _selectedSublayerIndex) {
                            _selectedSublayerIndex = -1;
                            _selectedSublayerIndex = index;
                            _selectedLocation = _data[index];
                            _isBottomSheetExpanded = false;
                            _bottomSheetHeight = 120.0;
                          } else {
                            _selectedSublayerIndex = -1;
                            _selectedLocation = null;
                          }
                        });
                      },
                    ),
                  ],
                )
              ],
            ),
          ),

          // Updated simple left-aligned title text
          Positioned(
            top: 35,
            left: 26, // Left-aligned
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: const Text(
                'Welfare Distribution Map',
                style: TextStyle(
                  fontSize: 26, // Increased font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          FloatingSearchBar(
            controller: _searchBarController,
            margins: const EdgeInsets.fromLTRB(16, 75, 16, 16),
            hint: 'Search municipalities...',
            height: 40, // Small height

            // Replace button with plain icon without margins
            leadingActions: [
              FloatingSearchBarAction.icon(
                icon: const Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 20,
                ),
                showIfOpened: true,
                size: 20, onTap: () {}, // Smaller size without padding
              ),
            ],

            // Add onFocusChanged callback to track when search bar is open
            onFocusChanged: (isFocused) {
              setState(() {
                _isSearchBarOpen = isFocused;
              });
            },

            // Other existing properties
            iconColor: Colors.grey,
            queryStyle: const TextStyle(fontSize: 14),
            hintStyle: const TextStyle(fontSize: 14),
            scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
            transitionDuration: const Duration(milliseconds: 800),
            transitionCurve: Curves.easeInOut,
            physics: const BouncingScrollPhysics(),
            axisAlignment: 0.0,
            openAxisAlignment: 0.0,
            width: 600,
            debounceDelay: const Duration(milliseconds: 500),
            borderRadius: BorderRadius.circular(15),
            elevation: 0,
            border: BorderSide(color: Colors.grey.shade900, width: 0.5),
            backgroundColor: Colors.white,
            onQueryChanged: (query) {
              setState(() {
                _searchTerm = query;
              });
            },
            onSubmitted: _handleSearch,
            textInputAction: TextInputAction.search,
            transition: CircularFloatingSearchBarTransition(),
            actions: [
              FloatingSearchBarAction(
                showIfOpened: false,
                child: CircularButton(
                  icon: const Icon(Icons.place),
                  onPressed: () {},
                ),
              ),
            ],
            builder: (context, transition) {
              final filteredList = _getFilteredList();
              return ClipRRect(
                borderRadius: BorderRadius.circular(
                    20), // Match dropdown corners with search bar
                child: Material(
                  color: Colors.white,
                  elevation: 0, // Remove shadow from dropdown
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.0), // Add outline to dropdown
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: filteredList
                        .map((place) => ListTile(
                              title: Text(place.name),
                              onTap: () => _selectMunicity(place),
                            ))
                        .toList(),
                  ),
                ),
              );
            },
          ),

          // Add filter chips below search bar
          _buildFilterChips(),

          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.5),
              child: const Center(
                child: SizedBox(
                  height: 25,
                  width: 25,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          // Always show the bottom sheet
          _buildBottomSheet(),
        ],
      ),
    );
  }
}

class _DataModel {
  _DataModel(this.name, this.latitude, this.longitude);
  final String name;
  final double latitude;
  final double longitude;
}
