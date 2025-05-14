import UIKit
import CoreLocation
import MapKit

class HomeViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var showWeatherButton: UIButton!

    var enteredCity: String = ""
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        setImageBackground()
        setupUI()
        setupLocation()
    }

    // MARK: - UI Düzenlemeleri
    func setupUI() {
        showWeatherButton.layer.cornerRadius = 12
        showWeatherButton.layer.shadowColor = UIColor.black.cgColor
        showWeatherButton.layer.shadowOpacity = 0.3
        showWeatherButton.layer.shadowOffset = CGSize(width: 2, height: 2)
        showWeatherButton.layer.shadowRadius = 4

        cityTextField.layer.cornerRadius = 8
        cityTextField.layer.borderWidth = 1
        cityTextField.layer.borderColor = UIColor.lightGray.cgColor

        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: cityTextField.frame.height))
        cityTextField.leftView = paddingView
        cityTextField.leftViewMode = .always
    }

    // MARK: - Konum Ayarları
    func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        // Yetki kontrolü
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }


    // MARK: - Konum Delegate Fonksiyonları
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first, let city = placemark.locality {
                    DispatchQueue.main.async {
                        self.cityTextField.text = city
                    }
                }
            }
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Konum alınamadı: \(error.localizedDescription)")
    }

    // MARK: - Görsel Arka Plan
    func setImageBackground() {
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.image = UIImage(named: "skybackground")
        backgroundImage.contentMode = .scaleAspectFill
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(backgroundImage)
        view.sendSubviewToBack(backgroundImage)

        NSLayoutConstraint.activate([
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    @IBAction func showOnMapTapped(_ sender: UIButton) {
        let cityToOpen = cityTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Istanbul"
        openCityInMaps(city: cityToOpen)
    }

    func openCityInMaps(city: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(city) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                print("Konum bulunamadı.")
                return
            }

            let coordinate = location.coordinate
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            mapItem.name = city
            mapItem.openInMaps(launchOptions: nil)
        }
    }


    // MARK: - Buton Aksiyonu
    @IBAction func showWeatherButtonTapped(_ sender: UIButton) {
        guard let city = cityTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !city.isEmpty else {
            let alert = UIAlertController(title: "Uyarı", message: "Lütfen bir şehir girin.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
            return
        }

        enteredCity = city
        performSegue(withIdentifier: "goToWeather", sender: self)
    }

    // MARK: - Segue Geçişi
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToWeather" {
            if let destinationVC = segue.destination as? ViewController {
                destinationVC.selectedCity = enteredCity
            }
        }
    }
    
}
