import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 46, weight: .regular))
                .foregroundColor(Color("AppPrimary"))
                .shadow(color: Color("AppPrimary").opacity(0.55), radius: 10)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("AppTextSecondary"))
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}
