//
//  ARViewContainer.swift
//  ClassifyItemsAR
//
//  Created by Alejandro Ignacio Aliaga Martinez on 19/1/23.
//

import SwiftUI
import RealityKit
import ARKit
import Vision
import CoreML

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        arView.session.run(configuration)
        context.coordinator.view = arView

        // Add tap handler
        arView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap))
        )
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
}

// MARK: - Coordinator
extension ARViewContainer {
    
    final class Coordinator: NSObject, ARSessionDelegate {
        // MARK: - Properties
        weak var view: ARView? = nil
        var currentFrame: ARFrame? = nil
        var classification: String = ""
        
        // MARK: - Delegates
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = view else {
                return
            }
            
            self.currentFrame = view.session.currentFrame
            self.classifyImage()
        }
        
        // MARK: - Functions
        private func classifyImage() {
            guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(UIDevice.current.orientation.rawValue)),
                  let capturedImage = self.currentFrame?.capturedImage else {
                return
            }
            
            let handler = VNImageRequestHandler(
                cvPixelBuffer: capturedImage,
                orientation: orientation,
                options: [:]
            )
            
            DispatchQueue.global().async {
                do {
                    let mobileNetV2Model = try MobileNetV2(configuration: MLModelConfiguration())
                    let vncoreModel = try VNCoreMLModel(for: mobileNetV2Model.model)
                    let request = VNCoreMLRequest(model: vncoreModel) { [weak self] request, error in
                        guard let classifications = request.results as? [VNClassificationObservation] else {
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self?.processClassifications(classifications)
                        }
                    }
                    
                    request.imageCropAndScaleOption = .centerCrop
                    
                    try handler.perform([request])
                } catch {
                    debugPrint("Error trying to perform the classification request. Details: \(error)")
                }
            }
        }
        
        private func processClassifications(_ classifications: [VNClassificationObservation]) {
            guard let observation = classifications.first,
                  let view = self.view else {
                return
            }
            
            // Clear the previous labels
            view.scene.anchors.removeAll()
            
            self.classification = String(observation.identifier.split(separator: ",").first ?? "Unknown element")
            debugPrint("Elements Detected: \(observation.identifier)")
            
            // Add a new anchor for the session
            let anchor = AnchorEntity(plane: .horizontal)
            let text = MeshResource.generateText(
                self.classification,
                extrusionDepth: 0.002,
                font: .systemFont(ofSize: 0.03, weight: .bold),
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            )
            
            let textEntity = ModelEntity(
                mesh: text,
                materials: [
                    SimpleMaterial(color: .white, roughness: 4, isMetallic: true)
                ]
            )
            
            textEntity.position.z -= 0.01
            anchor.addChild(textEntity)
            view.scene.addAnchor(anchor)
        }
        
    }
    
}
