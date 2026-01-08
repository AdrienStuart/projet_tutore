import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../coeur/services/maps_service.dart';

class MapWidget extends StatefulWidget {
  final LatLng center;
  final List<MapMarker>? markers;
  final List<LatLng>? polyline;
  final double? zoom;
  final Function(LatLng)? onTap;
  final double height;

  const MapWidget({
    super.key,
    required this.center,
    this.markers,
    this.polyline,
    this.zoom,
    this.onTap,
    this.height = 300,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late final MapController _controller;
  final MapsService _mapsService = MapsService();

  @override
  void initState() {
    super.initState();
    _controller = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _mapsService.provider.buildMap(
          center: widget.center,
          zoom: widget.zoom ?? 13,
          markers: widget.markers,
          polyline: widget.polyline,
          onTap: widget.onTap,
          controller: _controller,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
