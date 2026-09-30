//
//  CareWeekCalendarView.swift
//  Beanji
//
//  Created by Eugenia Fanenstiel on 20.08.26.
//

import SwiftUI
import Foundation

struct CareWeekCalendarView: View {
    let days: [CareCalendarDay]
    @Binding var selectedDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Week")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 0) {
                ForEach(days) { day in
                    let isSelected = Calendar.current.isDate(
                        day.date,
                        inSameDayAs: selectedDate
                    )

                    Button {
                        selectedDate = day.date
                    } label: {
                        VStack(spacing: 7) {
                            Text(
                                day.date.formatted(
                                    .dateTime.weekday(.abbreviated)
                                )
                            )
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                            Text(
                                day.date.formatted(
                                    .dateTime.day()
                                )
                            )
                            .font(.subheadline)
                            .fontWeight(day.isToday ? .bold : .medium)
                            .foregroundStyle(
                                day.isToday
                                    ? Color(.systemBackground)
                                    : Color.primary
                            )
                            .frame(width: 30, height: 30)
                            .background(
                                day.isToday
                                    ? Color.primary
                                    : Color.clear
                            )
                            .clipShape(Circle())

                            Group {
                                if day.hasWateringTask {
                                    Image(systemName: "drop.fill")
                                        .foregroundStyle(.blue)
                                        .accessibilityHidden(true)
                                }
                                else {
                                    Color.clear
                                        .frame(width: 14, height: 14)
                                }
                            }
                            .font(.caption)
                            .frame(height: 16)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isSelected ? Color.gray : Color.clear,
                                    lineWidth: 2
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        accessibilityLabel(for: day)
                    )
                    .accessibilityAddTraits(
                        isSelected ? .isSelected : []
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }


    private func accessibilityLabel(
        for day: CareCalendarDay
    ) -> String {
        let dateText = day.date.formatted(
            date: .complete,
            time: .omitted
        )

        if day.hasWateringTask {
            return LocalizedText.format(
                "%@, watering scheduled",
                dateText
            )
        }

        return LocalizedText.format(
            "%@, no watering scheduled",
            dateText
        )
    }
}

#Preview {
    @Previewable @State var selectedDate = Date()
    let calendar = Calendar.current
    let monday = calendar.date(
        from: DateComponents(
            year: 2026,
            month: 8,
            day: 17
        )
    )!

    let wateringDays = [1, 3, 5]
    let days = (0..<7).map { dayOffset in
        let date = calendar.date(
            byAdding: .day,
            value: dayOffset,
            to: monday,
        ) ?? monday

        return CareCalendarDay(
            date: date,
            isToday: calendar.isDateInToday(date),
            hasWateringTask: wateringDays.contains(dayOffset)
        )
    }
     CareWeekCalendarView(
        days: days,
        selectedDate: $selectedDate
     )
        .padding(20)
        .background(Color(.systemGroupedBackground))
}
