//
//  LabelsViewController.swift
//  DoCollabo
//
//  Created by delma on 2020/06/12.
//  Copyright © 2020 delma. All rights reserved.
//

import UIKit


final class LabelsViewController: UIViewController {

    @IBOutlet weak var titleHeaderBackgroundView: UIView!
    @IBOutlet weak var titleHeaderView: TitleHeaderView!
    @IBOutlet weak var labelsCollectionView: LabelsCollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private var popUpViewController: LabelPopUpViewController!

    private var labelsUseCase: UseCase!
    private var dataSource: LabelsCollectionViewDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        fetchLabels()
    }

    private func fetchLabels() {
        startActivityIndicator()
        let request = LabelsRequest().asURLRequest()
        labelsUseCase.getResources(request: request, dataType: [IssueLabel].self) { result in
            switch result {
            case .success(let labels):
                self.dataSource.updateLabels(labels)
            case .failure(let error):
                self.presentErrorAlert(error: error)
            }
        }
    }
    
    private func addLabel(bodyParams: Data) {
        let request = LabelsRequest(method: .POST, id: nil, bodyParams: bodyParams).asURLRequest()
        labelsUseCase.getStatus(request: request) { result in
            switch result {
            case .success(let success):
                self.fetchLabels()
            case .failure(let error):
                self.presentErrorAlert(error: error)
            }
        }
        
    }
}

// MARK:- Activity Indicator

extension LabelsViewController {
    private func startActivityIndicator() {
        activityIndicator.alpha = 1
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }

    private func stopActivityIndicator() {
        UIView.animateCurveEaseOut(withDuration: 0.5, animations: {
            self.activityIndicator.alpha = 0
        }) { (_) in
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        }
    }
}

// MARK:- Error Alert

extension LabelsViewController {
    private func presentErrorAlert(error: Error) {
        let alertController = ErrorAlertController(
            title: nil,
            message: error.localizedDescription,
            preferredStyle: .alert)
        alertController.configure(actionTitle: "재요청") { (_) in
            self.fetchLabels()
        }
        alertController.configure(actionTitle: "확인") { (_) in
            return
        }
        self.present(alertController, animated: true)
    }
}

// MARK:- HeaderViewActionDelegate

extension LabelsViewController: HeaderViewActionDelegate {
    func newButtonDidTap() {
        present(popUpViewController, animated: true, completion: nil)
    }
}

// MARK:- ButtonStackActionDelegate

extension LabelsViewController: PopUpViewControllerDelegate {
    func cancelButtonDidTap() {
        dismiss(animated: true, completion: nil)
    }

    func submitButtonDidTap(title: String, description: String?, additionalData: String?) {
        dismiss(animated: true, completion: nil)
        encodeLabel(title: title, description: description, color: additionalData!)
    }
    
    private func encodeLabel(title: String, description: String?, color: String) {
        let label = IssueLabel(id: nil, title: title, color: color, description: description)
        do {
            let encodedData = try JSONEncoder().encode(label)
            addLabel(bodyParams: encodedData)
        } catch {
            self.presentErrorAlert(error: NetworkError.BadRequest)
        }
    }
}

// MARK:- Configuration

extension LabelsViewController {
    private func configure() {
        configureUI()
        configureHeaderView()
        configurePopUpView()
        configureCollectionView()
        configureCollectionViewDataSource()
        configureUseCase()
    }

    private func configureUI() {
        labelsCollectionView.alpha = 0
    }

    private func configurePopUpView() {
        popUpViewController = LabelPopUpViewController()
        popUpViewController.modalPresentationStyle = .overCurrentContext
        popUpViewController.modalTransitionStyle = .crossDissolve
        popUpViewController.configureLabelPopupViewController()
        popUpViewController.popUpViewControllerDelegate = self
    }

    private func configureHeaderView() {
        titleHeaderBackgroundView.roundCorner(cornerRadius: 16.0)
        titleHeaderView.configureTitle("레이블")
        titleHeaderView.delegate = self
    }

    private func configureCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(
            width: labelsCollectionView.frame.width * 0.9,
            height: LabelCell.height)
        layout.scrollDirection = .vertical
        labelsCollectionView.collectionViewLayout = layout
    }

    private func configureCollectionViewDataSource() {
        dataSource = LabelsCollectionViewDataSource( changedHandler: { (_) in
            self.labelsCollectionView.reloadData()
            self.stopActivityIndicator()
            self.appearCollectionView()
        })
        labelsCollectionView.dataSource = dataSource
    }
    
    private func appearCollectionView() {
        UIView.animateCurveEaseOut(withDuration: 0.5, animations: {
            self.labelsCollectionView.alpha = 1.0
        }, completion: nil)
    }

    private func configureUseCase() {
        labelsUseCase = LabelsUseCase()
        fetchLabels()
    }
}
