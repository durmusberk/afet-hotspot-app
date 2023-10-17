import 'package:flutter/material.dart';
import 'package:test_app/screens/loading_page.dart';
import 'package:test_app/screens/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return const SliderWidget();
                  },
                );
              },
              child: Container(
                color: Colors.transparent,
                child: const SizedBox(
                  width: double.infinity,
                ),
              ),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoadingPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(
                      20.0), // Adjust the padding as needed
                  backgroundColor: Colors.red,
                  fixedSize:
                      Size(250, 250) // Daha sonra ekrana oranlayarak ayarla
                  ),
              child: const Text(
                'ACİL',
                style: TextStyle(
                    fontSize: 80), // Daha sonra ekrana oranlayarak ayarla
              ),
            ),
          ),
          const Expanded(
            child: SizedBox(
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}

class SliderWidget extends StatefulWidget {
  const SliderWidget({super.key});

  @override
  _SliderWidgetState createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  double sliderValue = 0.1;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.grey,
      child: Stack(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 60,
              trackShape: const RoundedRectSliderTrackShape(),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 30),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: sliderValue,
              thumbColor: Colors.red,
              activeColor: const Color.fromARGB(255, 238, 101, 92),
              inactiveColor: Colors.white,
              onChanged: (value) {
                setState(() {
                  sliderValue = value;
                });
                if (value == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
            ),
          ),
          Positioned(
            bottom: 40, // Daha sonra ekrana oranlayarak ayarla Center kullandım ama Incorrect use of ParentDataWidget verdi.
            left: (MediaQuery.of(context).size.width - 60) / 2,
            child: const Text(
              'Kaydır',
              style: TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

