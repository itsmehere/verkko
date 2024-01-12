//
//  ModalViewController.swift
//  Verkko
//
//  Created by Mihir Rao on 6/19/23.
//

import UIKit
import MapKit

class TapMapAnnotationDialogueVC: UIViewController {
    private let containerView = UIView()
    
    private let annotationNavigatorView = UIView()
    private let leftNavigatorButton = UIButton(type: .custom)
    private let rightNavigatorButton = UIButton(type: .custom)
    private var annotationNavigatorViewHeightAnchor: NSLayoutConstraint!
    private var isShowingAnnotationTableView = false
    
    private let landmarkLabel = UILabel()
    private let addressLabel = UILabel()
    private let launchMapsButton = VKButton(backgroundColor: .systemGreen, title: "")
    private let closeModalButton = UIButton(type: .close)
    
    private var mapView: MKMapView!
    lazy private var annotations: [TapMapAnnotation?] = {
        var annotations = mapView.annotations as? [TapMapAnnotation] ?? [TapMapAnnotation]()
        return annotations.sorted(by: { $0.id < $1.id })
    }()
    private var annotation: TapMapAnnotation! {
        didSet {
            updateAnnotationDialogueView()
        }
    }
    private var friend: VKUser!
    private var friendInfo: VKFriendInfo!
    private var location: CLLocationCoordinate2D!
    private var address: String!
    
    let padding: CGFloat = 20
    
    init(friend: VKUser, withFriendInfo friendInfo: VKFriendInfo, mapView: MKMapView, annotation: TapMapAnnotation) {
        super.init(nibName: nil, bundle: nil)
        
        self.mapView = mapView
        self.annotation = annotation
        self.friend = friend
        self.friendInfo = friendInfo
        self.location = CLLocationCoordinate2D(latitude: self.friendInfo.tappedLocations["lat"]![annotation.id], longitude: self.friendInfo.tappedLocations["lon"]![annotation.id])
        self.address = ""
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dismissTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissModal))
        dismissTapGestureRecognizer.delegate = self
        view.addGestureRecognizer(dismissTapGestureRecognizer)

        Utils.getAddressFromLatLon(lat: location.latitude, lon: location.longitude) { result in
            switch result {
            case .success(let address):
                self.address = address
                self.configureContainerView()
                self.configureLandmarkLabel()
                self.configureAddressLabel()
                self.configureCloseButton()
                self.configureActionButton()
            case .failure(let error):
                print("Error displaying last tap location: \(error.localizedDescription)")
            }
        }
        
        configureAnnotationNavigatorView()
        updateNavigatorButtons()
    }
    
    private func configureContainerView() {
        view.addSubview(containerView)
        
        containerView.backgroundColor = .systemBackground
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowRadius = 25
        containerView.layer.shadowOpacity = 0.5
        containerView.layer.shadowOffset = .zero
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.white.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 350),
            containerView.heightAnchor.constraint(equalToConstant: 185)
        ])
    }
    
    //MARK: - AnnotationNavigatorView
    private func configureAnnotationNavigatorView() {
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = .flexibleWidth
        blurView.translatesAutoresizingMaskIntoConstraints = false
        annotationNavigatorView.addSubview(blurView)
        
        annotationNavigatorView.layer.cornerRadius = 10
        annotationNavigatorView.layer.borderColor = UIColor.systemGreen.cgColor
        annotationNavigatorView.layer.borderWidth = 1
        annotationNavigatorView.clipsToBounds = true
        annotationNavigatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(annotationNavigatorView)
        
        let navigationHeaderView = UIView()
        navigationHeaderView.translatesAutoresizingMaskIntoConstraints = false
        annotationNavigatorView.addSubview(navigationHeaderView)
        

        leftNavigatorButton.setImage(UIImage(systemName: "arrow.left")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 23, weight: .semibold)), for: .normal)
        leftNavigatorButton.tintColor = .systemGreen
        leftNavigatorButton.addTarget(self, action: #selector(goToLeftAnnotation), for: .touchUpInside)
        leftNavigatorButton.translatesAutoresizingMaskIntoConstraints = false
        navigationHeaderView.addSubview(leftNavigatorButton)
        
        let goToAnnotationButton = UIButton(type: .custom)
        goToAnnotationButton.setTitle("Go To", for: .normal)
        goToAnnotationButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        goToAnnotationButton.backgroundColor = .lightGray.withAlphaComponent(0.8)
        goToAnnotationButton.layer.cornerRadius = 6
        goToAnnotationButton.setTitleColor(.white, for: .normal)
        goToAnnotationButton.translatesAutoresizingMaskIntoConstraints = false
        goToAnnotationButton.addTarget(self, action: #selector(showAnnotationTableView), for: .touchUpInside)
        navigationHeaderView.addSubview(goToAnnotationButton)
        
        rightNavigatorButton.setImage(UIImage(systemName: "arrow.right")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 23, weight: .semibold)), for: .normal)
        rightNavigatorButton.tintColor = .systemGreen
        rightNavigatorButton.addTarget(self, action: #selector(goToRightAnnotation), for: .touchUpInside)
        rightNavigatorButton.translatesAutoresizingMaskIntoConstraints = false
        navigationHeaderView.addSubview(rightNavigatorButton)
        
        let annotationTableView = UITableView()
        annotationTableView.translatesAutoresizingMaskIntoConstraints = false
        annotationTableView.delegate = self
        annotationTableView.dataSource = self
        annotationTableView.register(TapMapAnnotationCell.self, forCellReuseIdentifier: TapMapAnnotationCell.identifier)
        annotationTableView.separatorStyle = .singleLine
        annotationTableView.separatorColor = .systemGreen
        annotationTableView.backgroundColor = .clear
        annotationNavigatorView.addSubview(annotationTableView)
        
        annotationNavigatorViewHeightAnchor = annotationNavigatorView.heightAnchor.constraint(equalToConstant: 40)
        annotationNavigatorViewHeightAnchor.isActive = true
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: annotationNavigatorView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: annotationNavigatorView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: annotationNavigatorView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: annotationNavigatorView.bottomAnchor),
            
            navigationHeaderView.topAnchor.constraint(equalTo: annotationNavigatorView.topAnchor),
            navigationHeaderView.leadingAnchor.constraint(equalTo: annotationNavigatorView.leadingAnchor),
            navigationHeaderView.trailingAnchor.constraint(equalTo: annotationNavigatorView.trailingAnchor),
            navigationHeaderView.heightAnchor.constraint(equalToConstant: 40),
            
            leftNavigatorButton.leadingAnchor.constraint(equalTo: navigationHeaderView.leadingAnchor, constant: 10),
            leftNavigatorButton.centerYAnchor.constraint(equalTo: navigationHeaderView.centerYAnchor),
            
            goToAnnotationButton.centerYAnchor.constraint(equalTo: navigationHeaderView.centerYAnchor),
            goToAnnotationButton.centerXAnchor.constraint(equalTo: navigationHeaderView.centerXAnchor),
            goToAnnotationButton.widthAnchor.constraint(equalToConstant: 100),
            goToAnnotationButton.heightAnchor.constraint(equalToConstant: 25),
            
            rightNavigatorButton.trailingAnchor.constraint(equalTo: navigationHeaderView.trailingAnchor, constant: -10),
            rightNavigatorButton.centerYAnchor.constraint(equalTo: navigationHeaderView.centerYAnchor),
            
            annotationTableView.topAnchor.constraint(equalTo: navigationHeaderView.bottomAnchor),
            annotationTableView.leadingAnchor.constraint(equalTo: annotationNavigatorView.leadingAnchor),
            annotationTableView.trailingAnchor.constraint(equalTo: annotationNavigatorView.trailingAnchor),
            annotationTableView.bottomAnchor.constraint(equalTo: annotationNavigatorView.bottomAnchor),
            
            annotationNavigatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            annotationNavigatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            annotationNavigatorView.widthAnchor.constraint(equalToConstant: 250)
        ])
    }
    
    @objc private func goToLeftAnnotation() {
        if annotation.id - 1 >= 0 {
            if let leftAnnotation = annotations[annotation.id - 1] {
                setAnnotation(for: leftAnnotation)
                mapView.selectAnnotation(leftAnnotation, animated: true)
                centerMapView(annotation: annotation)
            }
        }
        
        updateNavigatorButtons()
    }
    
    @objc private func goToRightAnnotation() {
        if annotation.id + 1 <= annotations.count - 1 {
            if let rightAnnotation = annotations[annotation.id + 1] {
                setAnnotation(for: rightAnnotation)
                mapView.selectAnnotation(rightAnnotation, animated: true)
                centerMapView(annotation: annotation)
            }
        }
        updateNavigatorButtons()
    }
    
    private func centerMapView(annotation: MKAnnotation) {
        let centeredRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        mapView.setRegion(centeredRegion, animated: true)
    }
    
    private func updateNavigatorButtons() {
        updateLeftNavigatorButton()
        updateRightNavigatorButton()
    }
    
    private func updateLeftNavigatorButton() {
        if annotation.id - 1 >= 0 {
            leftNavigatorButton.isEnabled = true
        } else {
            leftNavigatorButton.isEnabled = false
        }
    }
    
    private func updateRightNavigatorButton() {
        if annotation.id + 1 <= annotations.count - 1 {
            rightNavigatorButton.isEnabled = true
        } else {
            rightNavigatorButton.isEnabled = false
        }
    }
    
    @objc private func showAnnotationTableView() {
        annotationNavigatorViewHeightAnchor.isActive = false
        
        if !isShowingAnnotationTableView {
            annotationNavigatorViewHeightAnchor = annotationNavigatorView.heightAnchor.constraint(equalToConstant: 200)

        } else {
            annotationNavigatorViewHeightAnchor = annotationNavigatorView.heightAnchor.constraint(equalToConstant: 40)
        }
        annotationNavigatorViewHeightAnchor.isActive = true
        
        isShowingAnnotationTableView.toggle()
    }
    
    private func setAnnotation(for annotation: TapMapAnnotation) {
        self.annotation = annotation
        location = CLLocationCoordinate2D(latitude: self.friendInfo.tappedLocations["lat"]![annotation.id], longitude: self.friendInfo.tappedLocations["lon"]![annotation.id])
    }
    
    
    //MARK: - Configure Container View
    private func configureLandmarkLabel() {
        containerView.addSubview(landmarkLabel)
        landmarkLabel.text = friendInfo.tappedTimes[annotation.id].formatted(date: .omitted, time: .shortened) + " · " +  friendInfo.tappedTimes[annotation.id].formatted(date: .abbreviated, time: .omitted)
        landmarkLabel.font = .systemFont(ofSize: 18, weight: .bold)
        landmarkLabel.textColor = .systemGreen
        landmarkLabel.translatesAutoresizingMaskIntoConstraints = false
        landmarkLabel.numberOfLines = 2
        
        NSLayoutConstraint.activate([
            landmarkLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding),
            landmarkLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
        ])
    }
    
    private func configureAddressLabel() {
        containerView.addSubview(addressLabel)
        addressLabel.text = address
        addressLabel.font = .systemFont(ofSize: 16, weight: .regular)
        addressLabel.textColor = .gray
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.numberOfLines = 2
        
        NSLayoutConstraint.activate([
            addressLabel.topAnchor.constraint(equalTo: landmarkLabel.bottomAnchor, constant: 18),
            addressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
            addressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding)
        ])
    }
    
    private func configureCloseButton() {
        containerView.addSubview(closeModalButton)
        closeModalButton.translatesAutoresizingMaskIntoConstraints = false
        closeModalButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            closeModalButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding - 5),
            closeModalButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -(padding - 5)),
        ])
    }
    
    private func configureActionButton() {
        containerView.addSubview(launchMapsButton)
        launchMapsButton.layer.cornerRadius = 10
        launchMapsButton.addTarget(self, action: #selector(launchMaps), for: .touchUpInside)
        launchMapsButton.setTitle("View in  Maps", for: .normal)
        
        NSLayoutConstraint.activate([
            launchMapsButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding),
            launchMapsButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
            launchMapsButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding),
            launchMapsButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func updateAnnotationDialogueView() {
        landmarkLabel.text = friendInfo.tappedTimes[annotation.id].formatted(date: .omitted, time: .shortened) + " · " +  friendInfo.tappedTimes[annotation.id].formatted(date: .abbreviated, time: .omitted)
        
        Utils.getAddressFromLatLon(lat: location.latitude, lon: location.longitude) { result in
            switch result {
            case .success(let address):
                self.addressLabel.text = address
            case .failure(let error):
                print("Error displaying last tap location: \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func dismissModal() {
        dismiss(animated: true)
        mapView.deselectAnnotation(annotation, animated: true)
    }
    
    @objc private func launchMaps() {
        Utils.launchMaps(location: location, address: address)
    }
}

//MARK: - Delegates
extension TapMapAnnotationDialogueVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}

extension TapMapAnnotationDialogueVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return annotations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TapMapAnnotationCell.identifier) as! TapMapAnnotationCell
        let tappedDate = friendInfo.tappedTimes[indexPath.row]
        cell.setCell(with: tappedDate)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedAnnotation = annotations[indexPath.row] {
            setAnnotation(for: selectedAnnotation)
            mapView.selectAnnotation(selectedAnnotation, animated: true)
            centerMapView(annotation: annotation)
        }
    }
}

//MARK: - TapMapAnnotationCell 
class TapMapAnnotationCell: UITableViewCell {
    static let identifier = "TapMapAnnotationCell"
    
    private let annotationTitleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCell(with tappedDate: Date) {
        annotationTitleLabel.text = tappedDate.formatted(date: .omitted, time: .shortened) + " · " +  tappedDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    private func configureCell() {
        backgroundColor = .clear
        
        annotationTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        annotationTitleLabel.textColor = .systemGreen
        annotationTitleLabel.textAlignment = .center
        addSubview(annotationTitleLabel)
        
        let horizontalPadding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            annotationTitleLabel.topAnchor.constraint(equalTo: topAnchor),
            annotationTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            annotationTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding),
            annotationTitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
