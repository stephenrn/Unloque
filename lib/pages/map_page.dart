import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore import

// Import the new files
import '../widgets/general_bottom_sheet.dart';
import '../widgets/category_filter_bottom_sheet.dart';
import '../widgets/selected_municipality_bottom_sheet.dart';
import '../models/data_model.dart';

class MapPage extends StatefulWidget {
  MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  _MapPageState();
  late MapShapeSource _shapeSource;
  late MapShapeSource _sublayerSource;
  late List<DataModel> _data;
  int _selectedIndex = -1;
  int _selectedSublayerIndex = -1;
  late MapZoomPanBehavior _zoomPanBehavior;
  bool _isLoading = true;
  late FloatingSearchBarController _searchBarController;
  String _searchTerm = '';

  // Modified bottom sheet variables
  bool _isBottomSheetExpanded = false;
  double _bottomSheetHeight = 120.0; // Changed back to 120.0 as default
  DataModel? _selectedLocation;

  // Quezon province default data
  final _quezonProvince = DataModel('Quezon Province', 14.2347, 121.9473);

  // Tab controller for bottom sheet tabs
  late TabController _tabController;

  // Add new state variable for filter selection
  String _selectedFilter = 'General'; // Default selected filter

  // Add a state variable to track search bar open state
  bool _isSearchBarOpen = false;

  // Add a map to store data values for each municipality
  final Map<String, double> _municipalityData = {};

  // Add a map to store population data from Firebase
  final Map<String, double> _populationData = {};
  bool _isPopulationDataLoaded = false;
  bool _isMapInitialized = false; // Add flag to track map initialization

  // Add a map to store raw population data, not just normalized values
  final Map<String, int> _rawPopulationData = {};
  int? _totalPopulation;

  // Add maps to store beneficiary data for each category
  final Map<String, Map<String, int>> _categoryData = {
    'Healthcare': {},
    'Social': {},
    'Educational': {}, // Changed from 'Education' to 'Educational'
  };

  // Add variables for category totals
  int? _healthcareTotalBeneficiaries;
  int? _socialTotalBeneficiaries;
  int? _educationTotalBeneficiaries;

  // Track if category data is loaded
  bool _isCategoryDataLoaded = false;

  List<DataModel> _generateDataModel() {
    return <DataModel>[
      DataModel('Agdangan', 13.885378, 121.9359),
      DataModel('Alabat', 14.1017, 122.0184),
      DataModel('Atimonan', 14.0048, 121.9199),
      DataModel('Buenavista', 13.7087, 122.4635),
      DataModel('Burdeos', 14.7446, 121.9262),
      DataModel('Calauag', 13.9547, 122.2872),
      DataModel('Candelaria', 13.9311, 121.4233),
      DataModel('Catanauan', 13.5927, 122.3208),
      DataModel('Dolores', 14.0244, 121.3681),
      DataModel('General Luna', 13.8425, 122.1494),
      DataModel('General Nakar', 14.7631, 121.6349),
      DataModel('Guinayangan', 13.9039, 122.4467),
      DataModel('Gumaca', 13.9208, 122.1000),
      DataModel('Infanta', 14.7425, 121.6494),
      DataModel('Jomalig', 14.7131, 122.3677),
      DataModel('Lopez', 13.8881, 122.2608),
      DataModel('Lucban', 14.1114, 121.5575),
      DataModel('Lucena City', 13.9419, 121.6169),
      DataModel('Macalelon', 13.7458, 122.1294),
      DataModel('Mauban', 14.1911, 121.7308),
      DataModel('Mulanay', 13.5264, 122.4044),
      DataModel('Padre Burgos', 13.9222, 121.8125),
      DataModel('Pagbilao', 13.9789, 121.7119),
      DataModel('Panukulan', 14.7472, 121.8139),
      DataModel('Patnanungan', 14.7481, 122.1736),
      DataModel('Perez', 14.1944, 121.9394),
      DataModel('Pitogo', 13.7972, 122.0936),
      DataModel('Plaridel', 13.9392, 122.0212),
      DataModel('Polillo', 14.7111, 121.9556),
      DataModel('Quezon', 14.0314, 122.1131),
      DataModel('Real', 14.6647, 121.6081),
      DataModel('Sampaloc', 14.1774, 121.6169),
      DataModel('San Andres', 13.3252, 122.6504),
      DataModel('San Antonio', 13.8951, 121.2970),
      DataModel('San Francisco', 13.3471, 122.5202),
      DataModel('San Narciso', 13.5689, 122.5662),
      DataModel('Sariaya', 13.9633, 121.5253),
      DataModel('Tagkawayan', 13.9647, 122.5472),
      DataModel('Tayabas City', 14.0244, 121.5847),
      DataModel('Tiaong', 13.9500, 121.3167),
      DataModel('Unisan', 13.8558, 121.9686),
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

    // Generate more diverse data values for each municipality
    // Use municipality name length + index to create distinct values
    for (int i = 0; i < _data.length; i++) {
      final municipality = _data[i];
      // Create a more random-like distribution by using name characters and index
      final nameValue =
          municipality.name.codeUnits.fold(0, (sum, char) => sum + char);
      final value = ((nameValue % 25) * 4) + (i % 5) * 5;
      _municipalityData[municipality.name] = value.toDouble().clamp(0.0, 100.0);
    }

    // We need to ensure map shows loading state until data is ready
    setState(() {
      _isLoading = true;
    });

    // Initialize map sources with placeholder data first
    _initializeMapSources();

    // Fetch population data from Firebase
    _fetchPopulationData();

    // Add call to fetch category data
    _fetchCategoryData();
  }

  // Initialize map sources before Firebase data is loaded
  void _initializeMapSources() {
    _shapeSource = MapShapeSource.asset(
      'lib/map/PHGeoJSON.json',
      shapeDataField: 'NAME_2',
      dataCount: _data.length,
      primaryValueMapper: (int index) => _data[index].name,
    );

    // Initial configuration with placeholder data
    _sublayerSource = MapShapeSource.asset(
      'lib/map/GeoJSON.json',
      shapeDataField: 'NAME_2',
      dataCount: _data.length,
      primaryValueMapper: (int index) => _data[index].name,
      shapeColorValueMapper: (int index) {
        final municipalityName = _data[index].name;
        // Initially use random data before Firebase loads
        return _municipalityData[municipalityName] ?? 0;
      },
      shapeColorMappers:
          _getPopulationColorMappers(), // Use blue shades by default for "General"
    );

    _isMapInitialized = true;
    debugPrint('Map sources initialized with placeholder data');
  }

  // Add method to fetch program categories
  Future<Map<String, String>> _fetchProgramCategories() async {
    Map<String, String> programCategories = {};

    try {
      // Query all organizations
      final orgSnapshot =
          await FirebaseFirestore.instance.collection('organizations').get();

      // For each organization, get its programs
      for (var orgDoc in orgSnapshot.docs) {
        final programsSnapshot = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgDoc.id)
            .collection('programs')
            .get();

        // Store program id -> category mapping
        for (var programDoc in programsSnapshot.docs) {
          final data = programDoc.data();
          final programId = data['id'] as String?;
          final category = data['category'] as String?;

          if (programId != null && category != null) {
            programCategories[programId] = category;
          }
        }
      }

      debugPrint('Fetched ${programCategories.length} program categories');
      return programCategories;
    } catch (e) {
      debugPrint('Error fetching program categories: $e');
      return {};
    }
  }

  // Add method to fetch beneficiary data by category
  Future<void> _fetchCategoryData() async {
    try {
      debugPrint('Fetching beneficiary data by category...');

      // First get program categories
      final programCategories = await _fetchProgramCategories();

      if (programCategories.isEmpty) {
        debugPrint('No program categories found, using placeholder data');
        _generatePlaceholderCategoryData();
        return;
      }

      // Fetch all beneficiary data from mapdata collection
      final beneficiarySnapshot = await FirebaseFirestore.instance
          .collection('mapdata')
          .where('type', isEqualTo: 'beneficiaries')
          .get();

      // Initialize category totals
      _healthcareTotalBeneficiaries = 0;
      _socialTotalBeneficiaries = 0;
      _educationTotalBeneficiaries = 0;

      // Process each beneficiary document
      for (var doc in beneficiarySnapshot.docs) {
        final data = doc.data();
        final programId = data['programId'] as String?;

        // Skip if no programId or not in our categories map
        if (programId == null || !programCategories.containsKey(programId)) {
          continue;
        }

        // Get the program category
        final category = programCategories[programId]!;

        // Create a normalized category name for consistent comparison
        String normalizedCategory = category.toLowerCase();

        // Skip if not one of our target categories
        bool isHealthcare = normalizedCategory == 'healthcare';
        bool isSocial = normalizedCategory == 'social';
        bool isEducational = normalizedCategory == 'education' ||
            normalizedCategory == 'educational';

        if (!isHealthcare && !isSocial && !isEducational) {
          continue;
        }

        // Fields to exclude when processing municipalities
        final excludeFields = [
          'programId',
          'programName',
          'organizationId',
          'type',
          'title',
          'updatedAt',
        ];

        // Get program's total beneficiaries (preferred method)
        int totalBeneficiaries = 0;
        if (data.containsKey('Total Beneficiaries')) {
          totalBeneficiaries = (data['Total Beneficiaries'] as num).toInt();
        } else {
          // Fallback: Calculate by summing municipality counts if Total Beneficiaries is missing
          for (String municipality in _data.map((e) => e.name)) {
            if (data.containsKey(municipality) &&
                !excludeFields.contains(municipality)) {
              totalBeneficiaries += (data[municipality] as num).toInt();
            }
          }
        }

        // Add the program's total beneficiaries to the appropriate category total
        if (isHealthcare) {
          _healthcareTotalBeneficiaries =
              (_healthcareTotalBeneficiaries ?? 0) + totalBeneficiaries;
        } else if (isSocial) {
          _socialTotalBeneficiaries =
              (_socialTotalBeneficiaries ?? 0) + totalBeneficiaries;
        } else if (isEducational) {
          _educationTotalBeneficiaries =
              (_educationTotalBeneficiaries ?? 0) + totalBeneficiaries;
        }

        // Process each municipality to populate municipality-specific data
        for (String municipality in _data.map((e) => e.name)) {
          if (data.containsKey(municipality) &&
              !excludeFields.contains(municipality)) {
            int beneficiaries = (data[municipality] as num).toInt();

            // Add to the category map for this municipality based on normalized categories
            if (isHealthcare) {
              _categoryData['Healthcare']![municipality] =
                  (_categoryData['Healthcare']![municipality] ?? 0) +
                      beneficiaries;
            } else if (isSocial) {
              _categoryData['Social']![municipality] =
                  (_categoryData['Social']![municipality] ?? 0) + beneficiaries;
            } else if (isEducational) {
              _categoryData['Educational']![municipality] =
                  (_categoryData['Educational']![municipality] ?? 0) +
                      beneficiaries;
            }
          }
        }
      }

      // Normalize the data for map display (0-100 scale)
      for (String category in _categoryData.keys) {
        int maxValue = 0;

        // Find the maximum value for this category
        for (String municipality in _data.map((e) => e.name)) {
          int value = _categoryData[category]![municipality] ?? 0;
          if (value > maxValue) maxValue = value;
        }

        // Normalize if maxValue is > 0
        if (maxValue > 0) {
          for (String municipality in _data.map((e) => e.name)) {
            int value = _categoryData[category]![municipality] ?? 0;
            _municipalityData[category + "_" + municipality] =
                (value / maxValue * 100).toDouble();
          }
        }
      }

      debugPrint(
          'Beneficiary data loaded: Healthcare=${_healthcareTotalBeneficiaries}, Social=${_socialTotalBeneficiaries}, Education=${_educationTotalBeneficiaries}');
      setState(() {
        _isCategoryDataLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading category data: $e');
      _generatePlaceholderCategoryData();
    } finally {
      setState(() {
        _isCategoryDataLoaded = true;
        _isLoading = false;
        _updateShapeSources();
      });
    }
  }

  // Generate placeholder category data when Firebase is unavailable
  void _generatePlaceholderCategoryData() {
    debugPrint('Generating placeholder category data');

    // Create some placeholder totals
    _healthcareTotalBeneficiaries = 75000;
    _socialTotalBeneficiaries = 125000;
    _educationTotalBeneficiaries = 98000;

    // Generate placeholder values for each municipality and category
    for (String category in _categoryData.keys) {
      for (var municipality in _data) {
        String name = municipality.name;

        // Create a deterministic but varied value based on name and category
        int nameHash = name.codeUnits.fold(0, (sum, char) => sum + char);
        int categoryHash =
            category.codeUnits.fold(0, (sum, char) => sum + char);
        int combinedHash = nameHash + categoryHash;

        // Store raw value in category data
        int value = 100 + (combinedHash % 9900); // 100-10000 range
        _categoryData[category]![name] = value;

        // Store normalized value (0-100) in municipality data for mapping
        _municipalityData[category + "_" + name] = (value % 100).toDouble();
      }
    }

    debugPrint(
        'Generated placeholder data for ${_data.length} municipalities in 3 categories');
  }

  // Add method to fetch population data from Firestore
  Future<void> _fetchPopulationData() async {
    try {
      debugPrint('Fetching population data from Firebase...');

      // Use a try-catch block without the timeout that was causing issues
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('mapdata')
            .doc('quezon_population')
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;

          // Store the total population
          if (data.containsKey('Total Population')) {
            _totalPopulation = (data['Total Population'] as num).toInt();
          }

          // Store raw population data
          for (String municipality in _data.map((e) => e.name)) {
            if (data.containsKey(municipality)) {
              _rawPopulationData[municipality] =
                  (data[municipality] as num).toInt();
            }
          }

          // Find min and max population for better normalization
          double minPopulation = double.infinity;
          double maxPopulation = 0;

          // First pass to find min/max values
          for (String municipality in _data.map((e) => e.name)) {
            if (data.containsKey(municipality)) {
              double populationValue = (data[municipality] as num).toDouble();
              if (populationValue > 0) {
                minPopulation = minPopulation > populationValue
                    ? populationValue
                    : minPopulation;
                maxPopulation = maxPopulation < populationValue
                    ? populationValue
                    : maxPopulation;
              }
            }
          }

          // Convert raw population to normalized values between 0-100
          double range = maxPopulation - minPopulation;
          if (range <= 0) range = 1; // Prevent division by zero

          for (String municipality in _data.map((e) => e.name)) {
            if (data.containsKey(municipality)) {
              double populationValue = (data[municipality] as num).toDouble();
              double normalizedValue =
                  ((populationValue - minPopulation) / range * 100)
                      .clamp(0.0, 100.0);
              _populationData[municipality] = normalizedValue;
            } else {
              // Default value if population data is missing
              _populationData[municipality] = 10.0;
            }
          }

          debugPrint(
              'Population data loaded successfully for ${_populationData.length} municipalities');
        } else {
          debugPrint(
              'Population document does not exist, using placeholder data');
          _generatePlaceholderPopulationData();
        }
      } catch (firestoreError) {
        // Handle Firestore specific errors
        debugPrint('Firestore error: $firestoreError');
        _generatePlaceholderPopulationData();
      }
    } catch (e) {
      debugPrint('Error loading population data: $e');
      // Ensure we have fallback data even if Firebase fails
      _generatePlaceholderPopulationData();
    } finally {
      setState(() {
        _isPopulationDataLoaded = true;
        _isLoading = false;

        // Update the shape sources with real population data now
        _updateShapeSources();
      });
    }
  }

  // Generate placeholder population data when Firebase is unavailable
  void _generatePlaceholderPopulationData() {
    // Generate placeholder for total population too
    _totalPopulation = 1950459; // Example total population for Quezon

    // Generate placeholder population values based on municipality name
    for (var municipality in _data) {
      String name = municipality.name;
      // Create a deterministic but varied value based on name
      int nameHash = name.codeUnits.fold(0, (sum, char) => sum + char);
      int rawValue =
          10000 + (nameHash % 90000); // Generate values between 10k and 100k
      // Store both raw and normalized values
      _rawPopulationData[name] = rawValue;
      _populationData[name] = (rawValue % 100).toDouble();
    }

    debugPrint(
        'Generated placeholder population data for ${_data.length} municipalities');
  }

  // Update shape sources method to reflect current filter selection
  void _updateShapeSources() {
    if (!_isMapInitialized) {
      debugPrint('Map not initialized yet, deferring shape source update');
      return;
    }

    if (_selectedFilter == 'General' && !_isPopulationDataLoaded) {
      debugPrint(
          'Population data not loaded yet, deferring shape source update');
      return;
    }

    if (_selectedFilter != 'General' && !_isCategoryDataLoaded) {
      debugPrint('Category data not loaded yet, deferring shape source update');
      return;
    }

    debugPrint('Updating shape sources for filter: $_selectedFilter');

    _sublayerSource = MapShapeSource.asset(
      'lib/map/GeoJSON.json',
      shapeDataField: 'NAME_2',
      dataCount: _data.length,
      primaryValueMapper: (int index) => _data[index].name,
      shapeColorValueMapper: (int index) {
        final municipalityName = _data[index].name;

        if (_selectedFilter == 'General') {
          final value = _populationData[municipalityName] ?? 0;
          return value;
        } else {
          // Use the category-specific data
          final value =
              _municipalityData[_selectedFilter + "_" + municipalityName] ?? 0;
          return value;
        }
      },
      shapeColorMappers: _selectedFilter == 'General'
          ? _getPopulationColorMappers()
          : _getCategoryColorMappers(_selectedFilter),
    );

    // Force a rebuild to ensure the map updates
    if (mounted) {
      setState(() {
        debugPrint('Map updated with new shape sources');
      });
    }
  }

  @override
  void dispose() {
    _searchBarController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<DataModel> _getFilteredList() {
    if (_searchTerm.isEmpty) return [];
    return _data
        .where((item) =>
            item.name.toLowerCase().contains(_searchTerm.toLowerCase()))
        .toList();
  }

  void _selectMunicity(DataModel selected) {
    final index = _data.indexWhere((item) => item.name == selected.name);
    if (index != -1) {
      // Get current filter to preserve it
      final currentFilter = _selectedFilter;

      _zoomPanBehavior.focalLatLng =
          MapLatLng(selected.latitude, selected.longitude);
      _zoomPanBehavior.zoomLevel = 9;

      setState(() {
        _selectedSublayerIndex = index;
        _selectedLocation = selected;
        _isBottomSheetExpanded = false;
        _bottomSheetHeight = 120.0;
        // Preserve current filter instead of resetting to General
        _selectedFilter = currentFilter;
        debugPrint(
            'Search selected municipality: ${selected.name} with filter: $_selectedFilter');
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

  // Method to handle filter selection
  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
      // Reset bottom sheet to collapsed state when changing categories
      _isBottomSheetExpanded = false;
      _bottomSheetHeight = 120.0;

      // Update shape sources when filter changes to apply correct color mapping
      _updateShapeSources();
    });
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
      'Educational' // Changed from 'Education' to 'Educational'
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

    // Debug print to help track what's happening with filters
    debugPrint(
        'Building bottom sheet: filter=$_selectedFilter, location=${displayLocation.name}, default=$isDefaultView');

    // If a municipality is selected, always show the municipality-specific bottom sheet
    // regardless of the selected filter
    if (!isDefaultView) {
      // Get municipality data
      int? municipalityPopulation;
      Map<String, int> beneficiaryData = {};

      // Get population data for this municipality
      if (_rawPopulationData.containsKey(_selectedLocation!.name)) {
        municipalityPopulation = _rawPopulationData[_selectedLocation!.name];
      }

      // Get beneficiary data for all categories for this municipality
      for (String category in _categoryData.keys) {
        if (_categoryData[category]!.containsKey(_selectedLocation!.name)) {
          beneficiaryData[category] =
              _categoryData[category]![_selectedLocation!.name]!;
        }
      }

      return SelectedMunicipalityBottomSheet(
        location: displayLocation,
        isExpanded: _isBottomSheetExpanded,
        sheetHeight: _bottomSheetHeight,
        onClose: _resetToQuezonProvince,
        onDragUpdate: _handleDragUpdate,
        municipalityPopulation: municipalityPopulation,
        beneficiaryData: beneficiaryData,
        categoryTotals: {
          'Healthcare': _healthcareTotalBeneficiaries,
          'Social': _socialTotalBeneficiaries,
          'Educational': _educationTotalBeneficiaries,
        },
        selectedFilter: _selectedFilter,
      );
    }

    // If in province view (no municipality selected), switch based on filter
    if (_selectedFilter != 'General') {
      // For category filters, show the category filter bottom sheet
      int? categoryTotal;
      if (_selectedFilter == 'Healthcare') {
        categoryTotal = _healthcareTotalBeneficiaries;
      } else if (_selectedFilter == 'Social') {
        categoryTotal = _socialTotalBeneficiaries;
      } else if (_selectedFilter == 'Educational') {
        categoryTotal = _educationTotalBeneficiaries;
      }

      return CategoryFilterBottomSheet(
        selectedFilter: _selectedFilter,
        isExpanded: _isBottomSheetExpanded,
        sheetHeight: _bottomSheetHeight,
        onClose: () => _onFilterSelected('General'),
        onDragUpdate: _handleDragUpdate,
        categoryTotalBeneficiaries: categoryTotal,
      );
    }

    // Default to general bottom sheet for province view with General filter
    return GeneralBottomSheet(
      location: displayLocation,
      isDefaultView: isDefaultView,
      isExpanded: _isBottomSheetExpanded,
      sheetHeight: _bottomSheetHeight,
      onClose: _resetToQuezonProvince,
      onDragUpdate: _handleDragUpdate,
      onToggleExpansion: _toggleBottomSheetExpansion,
      tabController: _tabController,
      totalPopulation: _totalPopulation,
      healthcareTotalBeneficiaries: _healthcareTotalBeneficiaries,
      socialTotalBeneficiaries: _socialTotalBeneficiaries,
      educationTotalBeneficiaries: _educationTotalBeneficiaries,
      // Add these new parameters for AI analysis
      rawPopulationData: _rawPopulationData,
      categoryData: _categoryData,
    );
  }

  MapShapeSublayer _buildSublayer() {
    return MapShapeSublayer(
      source: _sublayerSource,
      strokeColor: Colors.grey[800],
      strokeWidth: 1,
      selectedIndex: _selectedSublayerIndex,
      selectionSettings: const MapSelectionSettings(
          color: Color.fromARGB(255, 27, 160, 227),
          strokeColor: Color.fromARGB(255, 255, 255, 255),
          strokeWidth: 1),
      onSelectionChanged: (int index) {
        // Preserve current filter
        final currentFilter = _selectedFilter;

        _zoomPanBehavior.focalLatLng =
            MapLatLng(_data[index].latitude, _data[index].longitude);
        _zoomPanBehavior.zoomLevel = 9;

        setState(() {
          if (index != _selectedSublayerIndex) {
            _selectedSublayerIndex = -1;
            _selectedSublayerIndex = index;
            _selectedLocation = _data[index];
            _isBottomSheetExpanded = false;
            _bottomSheetHeight = 120.0;
            // Preserve filter selection instead of resetting to General
            _selectedFilter = currentFilter;
            debugPrint(
                'Selected municipality: ${_data[index].name} with filter: $_selectedFilter');
          } else {
            _selectedSublayerIndex = -1;
            _selectedLocation = null;
          }
        });
      },
    );
  }

  // Get color mappers for population data (grey gradient with 20 shades)
  List<MapColorMapper> _getPopulationColorMappers() {
    // Create a list to hold all color mappers
    List<MapColorMapper> mappers = [];

    // Define 20 shades of grey with 5% intervals
    for (int i = 0; i < 20; i++) {
      // Calculate start and end values for the current interval (5% each)
      double from = i * 5.0;
      double to = (i + 1) * 5.0;

      // Generate appropriate shade of grey
      // The greyscale goes from very light (50) to very dark (900)
      // We'll interpolate between these values

      // The standard Material grey scale has: 50, 100, 200, 300, 400, 500, 600, 700, 800, 900
      // For 20 shades, we'll need to create intermediate values

      // Map the range 0-20 to the range 50-900 for the grey scale
      double greyValue = 50.0 + (i / 19.0) * 850.0;

      // Find the closest standard grey values and interpolate between them
      int lowerGrey = (greyValue ~/ 100) * 100;
      if (lowerGrey < 50) lowerGrey = 50;

      int upperGrey = lowerGrey + 100;
      if (lowerGrey == 50) upperGrey = 100;
      if (upperGrey > 900) upperGrey = 900;

      // Calculate interpolation factor between the two standard grey values
      double factor = (greyValue - lowerGrey) / (upperGrey - lowerGrey);

      // Get or create the appropriate color
      Color color;
      if (lowerGrey == upperGrey) {
        color = Colors.grey[lowerGrey]!;
      } else {
        // For standard Material Design grey levels
        if (lowerGrey % 100 == 0 || lowerGrey == 50) {
          if (upperGrey % 100 == 0 || upperGrey == 50) {
            color = Color.lerp(
                Colors.grey[lowerGrey]!, Colors.grey[upperGrey]!, factor)!;
          } else {
            // Handle the case where upperGrey is non-standard
            color = Colors.grey[lowerGrey]!;
          }
        } else {
          // Handle non-standard lower grey value
          color = Colors.grey[100]!; // Fallback
        }
      }

      // Add the mapper with a formatted text label
      mappers.add(MapColorMapper(
        from: from,
        to: to,
        color: color,
        text: '${from.toStringAsFixed(0)}-${to.toStringAsFixed(0)}%',
      ));
    }

    return mappers;
  }

  // Get category-specific color mappers
  List<MapColorMapper> _getCategoryColorMappers(String category) {
    List<MapColorMapper> mappers = [];

    // Define colors based on category
    List<Color> colorShades;

    switch (category) {
      case 'Healthcare':
        // Red shades for healthcare
        colorShades = [
          Colors.red[50]!,
          Colors.red[100]!,
          Colors.red[200]!,
          Colors.red[300]!,
          Colors.red[400]!,
          Colors.red[500]!,
          Colors.red[600]!,
          Colors.red[700]!,
          Colors.red[800]!,
          Colors.red[900]!,
        ];
        break;
      case 'Social':
        // Green shades for social
        colorShades = [
          Colors.green[50]!,
          Colors.green[100]!,
          Colors.green[200]!,
          Colors.green[300]!,
          Colors.green[400]!,
          Colors.green[500]!,
          Colors.green[600]!,
          Colors.green[700]!,
          Colors.green[800]!,
          Colors.green[900]!,
        ];
        break;
      case 'Education':
        // Blue shades for education
        colorShades = [
          Colors.blue[50]!,
          Colors.blue[100]!,
          Colors.blue[200]!,
          Colors.blue[300]!,
          Colors.blue[400]!,
          Colors.blue[500]!,
          Colors.blue[600]!,
          Colors.blue[700]!,
          Colors.blue[800]!,
          Colors.blue[900]!,
        ];
        break;
      default:
        // Default to blue shades
        colorShades = [
          Colors.blue[50]!,
          Colors.blue[100]!,
          Colors.blue[200]!,
          Colors.blue[300]!,
          Colors.blue[400]!,
          Colors.blue[500]!,
          Colors.blue[600]!,
          Colors.blue[700]!,
          Colors.blue[800]!,
          Colors.blue[900]!,
        ];
    }

    // Create 10 color mappers with 10% range each
    for (int i = 0; i < 10; i++) {
      double from = i * 10.0;
      double to = (i + 1) * 10.0;

      mappers.add(MapColorMapper(
        from: from,
        to: to,
        color: colorShades[i],
        text: '${from.toStringAsFixed(0)}-${to.toStringAsFixed(0)}%',
      ));
    }

    return mappers;
  }

  // Format number with commas
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'Building MapPage with filter: $_selectedFilter, population data loaded: $_isPopulationDataLoaded');

    if (_isLoading) {
      return Scaffold(
        body: Container(
          color: Colors.white,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading map data...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Change the background of the map to light blue
          Container(
            color: Colors
                .blue.shade100, // Light blue background for the entire map
          ),

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
                  color: Colors.white, // Changed to white for PHGeoJSON
                  strokeColor: Colors.white, // Light blue border
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
                    _buildSublayer(), // Use the extracted method here
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
