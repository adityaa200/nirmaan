import cv2
import os
import sys

def detect_classroom_attendance(image_path, output_path="outputs/detected_attendance.jpg"):
    """
    Step 1 PoC: Detects faces in a classroom photo and counts total attendance.
    """
    if not os.path.exists(image_path):
        print(f"[ERROR] Image not found at path: {image_path}")
        print("Please place a sample group photo in 'sample_images/' directory.")
        return 0

    # Load image
    image = cv2.imread(image_path)
    gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Load OpenCV built-in frontal face Haar Cascade
    cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
    face_cascade = cv2.CascadeClassifier(cascade_path)

    # Detect faces
    faces = face_cascade.detectMultiScale(
        gray_image,
        scaleFactor=1.1,
        minNeighbors=5,
        minSize=(30, 30)
    )

    attendance_count = len(faces)
    print("==========================================")
    print(f" SUCCESS: Processed '{image_path}'")
    print(f" Total Students Detected (Headcount): {attendance_count}")
    print("==========================================")

    # Draw bounding boxes and labels on detected faces
    for (x, y, w, h) in faces:
        cv2.rectangle(image, (x, y), (x + w, y + h), (0, 255, 0), 2)
        cv2.putText(image, "Student", (x, y - 10), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1)

    # Add overlay summary text
    summary_text = f"Nirmaan AI Attendance Count: {attendance_count}"
    cv2.putText(image, summary_text, (20, 40), 
                cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 0, 255), 2)

    # Save output image
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    cv2.imwrite(output_path, image)
    print(f"[INFO] Annotated image saved to: {output_path}")

    return attendance_count

if __name__ == "__main__":
    test_image = "sample_images/test_group.jpg"
    
    if len(sys.argv) > 1:
        test_image = sys.argv[1]

    detect_classroom_attendance(test_image)