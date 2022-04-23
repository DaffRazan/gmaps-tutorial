import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_tutorial/directions_model.dart';
import 'package:google_maps_tutorial/directions_repository.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  late GoogleMapController _gMapController;

  // Markers
  Marker? _origin;
  Marker? _destination;

  // Direction info
  Directions? _info;

  @override
  void dispose() {
    _gMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps'),
        actions: [
          if (_origin != null)
            TextButton(
                onPressed: () => _gMapController.animateCamera(
                    CameraUpdate.newCameraPosition(CameraPosition(
                        target: _origin!.position, zoom: 14.5, tilt: 50.0))),
                style: TextButton.styleFrom(
                    primary: Colors.blue,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600)),
                child: const Text('ORIGIN')),
          if (_destination != null)
            TextButton(
                onPressed: () => _gMapController.animateCamera(
                    CameraUpdate.newCameraPosition(CameraPosition(
                        target: _destination!.position,
                        zoom: 14.5,
                        tilt: 50.0))),
                style: TextButton.styleFrom(
                    primary: Colors.red,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600)),
                child: const Text('DESTINATION'))
        ],
      ),
      body: Stack(alignment: Alignment.center, children: [
        GoogleMap(
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          initialCameraPosition: _initialCameraPosition,
          onMapCreated: (controller) => _gMapController = controller,
          markers: {
            if (_origin != null) _origin!,
            if (_destination != null) _destination!
          },
          polylines: {
            if (_info != null)
              Polyline(
                polylineId: const PolylineId('overview_polyline'),
                color: Colors.red,
                width: 5,
                points: _info!.polylinePoints
                    .map((e) => LatLng(e.latitude, e.longitude))
                    .toList(),
              ),
          },
          onLongPress: _addMarker,
        ),
        if (_info != null)
          Positioned(
            top: 20.0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 6.0,
                horizontal: 12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.yellowAccent,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 6.0,
                  )
                ],
              ),
              child: Text(
                '${_info!.totalDistance}, ${_info!.totalDuration}',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.black,
        onPressed: () => _gMapController.animateCamera(_info != null
            ? CameraUpdate.newLatLngBounds(_info!.bounds, 100.0)
            : CameraUpdate.newCameraPosition(_initialCameraPosition)),
        child: const Icon(
          Icons.center_focus_strong,
          color: Colors.white,
        ),
      ),
    );
  }

  void _addMarker(LatLng position) async {
    if (_origin == null || (_origin != null && _destination != null)) {
      // set origin
      setState(() {
        _origin = Marker(
            markerId: const MarkerId('origin'),
            infoWindow: const InfoWindow(title: 'Origin'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            position: position);

        // set destination to null
        _destination = null;

        // reset info
        _info = null;
      });
    } else {
      // set destination
      setState(() {
        _destination = Marker(
            markerId: const MarkerId('destination'),
            infoWindow: const InfoWindow(title: 'Destination'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            position: position);
      });

      // Get directions
      final directions = await DirectionsRepository()
          .getDirections(origin: _origin!.position, destination: position);
      setState(() {
        _info = directions;
      });
    }
  }
}
