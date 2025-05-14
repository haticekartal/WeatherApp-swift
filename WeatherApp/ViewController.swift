import UIKit
import MapKit
import Alamofire

struct Forecast {
    let date: String
    let temperature: Double
    let humidity: Int
    let windSpeed: Double
    let icon: String
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var windLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var forecastTableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    @IBOutlet weak var temperatureCard: UIView!
    @IBOutlet weak var humidityCard: UIView!
    @IBOutlet weak var windCard: UIView!
    
    @IBOutlet weak var iconTemp: UIImageView!
    @IBOutlet weak var iconHumidity: UIImageView!
    @IBOutlet weak var iconWind: UIImageView!

    var forecasts: [Forecast] = []
    var selectedCity: String?
    var allForecasts: [Forecast] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Hava Durumu"
        setBackgroundImage()
        styleCards()
        
        iconTemp.image = UIImage(named: "tempicon")
        iconHumidity.image = UIImage(named: "humidityicon")
        iconWind.image = UIImage(named: "windicon")

        forecastTableView.delegate = self
        forecastTableView.dataSource = self

        let cityToShow = selectedCity ?? "Istanbul"
        cityLabel.text = cityToShow

        fetchWeatherAndForecast(for: cityToShow)
    }

    func setBackgroundImage() {
        let backgroundImage = UIImageView(frame: view.bounds)
        backgroundImage.image = UIImage(named: "weatherbackground")
        backgroundImage.contentMode = .scaleAspectFill
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false

        view.insertSubview(backgroundImage, at: 0)

        NSLayoutConstraint.activate([
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    @IBAction func shareButtonTapped(_ sender: UIButton) {
        let shareText = "Bugün \(cityLabel.text ?? "") için hava \(temperatureLabel.text ?? "")!"
        let vc = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        present(vc, animated: true)
    }

    func getLocalIconName(from iconCode: String) -> String {
        switch iconCode {
        case "rain", "showers", "tstorms":
            return "rainicon"
        case "snow":
            return "snowicon"
        case "partly-cloudy-day", "partly-cloudy-night":
            return "partlyCloudyicon"
        case "cloudy", "overcast":
            return "cloudyicon"
        case "clear-day", "clear-night":
            return "sunicon"
        default:
            return "sunicon"
        }
    }

    func styleCards() {
        let cards = [temperatureCard, humidityCard, windCard]
        for card in cards {
            card?.layer.cornerRadius = 16
            card?.layer.shadowColor = UIColor.black.cgColor
            card?.layer.shadowOpacity = 0.15
            card?.layer.shadowOffset = CGSize(width: 2, height: 2)
            card?.layer.shadowRadius = 6
            card?.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        }
    }

    func fetchWeatherAndForecast(for city: String) {
        let apiKey = "NKTLC7LY6K82SMSMKLPSZR4VM"
        let urlString = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/\(city)?unitGroup=metric&key=\(apiKey)&include=current,days"

        AF.request(urlString).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let json = value as? [String: Any] {
                    var parsedForecasts: [Forecast] = []

                    // ANLIK VERİ
                    if let current = json["currentConditions"] as? [String: Any],
                       let temp = current["temp"] as? Double,
                       let humidity = current["humidity"] as? Double,
                       let wind = current["windspeed"] as? Double,
                       let icon = current["icon"] as? String {
                        
                        DispatchQueue.main.async {
                            self.temperatureLabel.text = "\(Int(temp))°C"
                            self.humidityLabel.text = "%\(Int(humidity))"
                            self.windLabel.text = "\(Int(wind)) km/h"
                            self.weatherIcon.image = UIImage(named: self.getLocalIconName(from: icon))
                        }
                    }

                    // GÜNLÜK TAHMİNLER
                    if let days = json["days"] as? [[String: Any]] {
                        for day in days.prefix(15) {
                            if let date = day["datetime"] as? String,
                               let temp = day["temp"] as? Double,
                               let humidity = day["humidity"] as? Double,
                               let wind = day["windspeed"] as? Double,
                               let icon = day["icon"] as? String {

                                let forecast = Forecast(
                                    date: date,
                                    temperature: temp,
                                    humidity: Int(humidity),
                                    windSpeed: wind,
                                    icon: icon
                                )
                                parsedForecasts.append(forecast)
                            }
                        }

                        DispatchQueue.main.async {
                            self.allForecasts = parsedForecasts
                            self.updateForecastDisplay()
                        }
                    }
                }

            case .failure(let error):
                print("Alamofire ile veri çekme hatası: \(error)")
            }
        }
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        updateForecastDisplay()
    }

    func updateForecastDisplay() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            forecasts = Array(allForecasts.prefix(1))
        case 1:
            forecasts = Array(allForecasts.prefix(5))
        case 2:
            forecasts = Array(allForecasts.prefix(15))
        default:
            break
        }
        forecastTableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forecasts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ForecastCell", for: indexPath) as? ForecastTableViewCell else {
            return UITableViewCell()
        }

        let forecast = forecasts[indexPath.row]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: forecast.date) {
            let displayFormatter = DateFormatter()
            displayFormatter.locale = Locale(identifier: "tr_TR")
            displayFormatter.dateFormat = "dd MMMM EEEE"
            cell.dayLabel.text = displayFormatter.string(from: date)
        } else {
            cell.dayLabel.text = forecast.date
        }

        cell.weatherIconView.image = UIImage(named: getLocalIconName(from: forecast.icon))
        cell.tempLabel.text = "\(Int(forecast.temperature))°C"
        cell.windLabel.text = "\(Int(forecast.windSpeed)) km/h"
        cell.humidityLabel.text = "%\(forecast.humidity)"

        return cell
    }
}
