import SwiftUI

/// Reusable circular avatar. Shows the user's photo if set, or a default person icon.
/// Pass `crown` to float an emoji above the circle (e.g. "👑", "⭐️").
struct AvatarView: View {
    let imageData: Data?
    let size: CGFloat
    var crown: String? = nil

    var body: some View {
        VStack(spacing: -(size * 0.12)) {
            if let c = crown {
                Text(c)
                    .font(.system(size: size * 0.42))
                    .shadow(radius: 2)
            }
            avatarCircle
        }
    }

    private var avatarCircle: some View {
        Group {
            if let data = imageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.accentColor.opacity(0.15))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.55), lineWidth: 2))
    }
}

#Preview {
    VStack(spacing: 24) {
        AvatarView(imageData: nil, size: 80)
        AvatarView(imageData: nil, size: 80, crown: "👑")
    }
    .padding()
}
