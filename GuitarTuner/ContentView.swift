//
//  ContentView.swift
//  GuitarTuner
//
//  Created by albertma on 2024/10/31.
//


import SwiftUI

struct ContentView: View {
    @State private var selectedPanel: String? = "Tuning"
    var body: some View {
        NavigationView {
                // 左侧菜单
                VStack(spacing: 10){
                    
                    // 调音按钮
                    SideMenuButton(
                        label: "Tuning Panel",
                        icon: "tuningfork",
                        isSelected: selectedPanel == "Tuning"
                    ) {
                        selectedPanel = "Tuning"
                    }
                    // 节奏按钮
                    SideMenuButton(
                        label: "Rhythm Panel",
                        icon: "metronome",
                        isSelected: selectedPanel == "Rhythm"
                    ) {
                        selectedPanel = "Rhythm"
                    }
                    
                    // 弹奏按钮
                    SideMenuButton(
                        label: "Play Panel",
                        icon: "guitars",
                        isSelected: selectedPanel == "Play"
                    ) {
                        selectedPanel = "Play"
                    }
                }
                .frame(minWidth: 200)
                .padding()
                //.background(Color(.systemGray))
                
                // 右侧内容面板
                VStack {
                    if selectedPanel == "Tuning" {
                        TuningPanelView()
                    } else if selectedPanel == "Rhythm" {
                        RhythmPanelView()
                    } else if selectedPanel == "Play" {
                        PlayPanelView()
                    } else {
                        Text("Select a panel from the menu")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    
}


struct TuningPanelView: View {
    @ObservedObject private var tuner = Tuner()
    @State private var sliderValue: Double = 0.0
    @State private var isTuning = false  // 控制调音状态
    let currConfig = UkuleleTunerConfig()
    
    var body: some View {
        
       
        VStack {
            HStack{
                Text("Current Tone：").foregroundColor(.blue).font(.largeTitle)
                Text("\(tuner.result.tone?.pitch ?? "")")
                    .foregroundColor((TunerCode.tunningDone == tuner.result.tunerCode) ? .green : .red)
                    .font(.largeTitle)
                    .padding()
            }
            RulerView(value: Binding(
                get: { Double(tuner.result.diffFreq) },
                set: { newValue in tuner.result.diffFreq = Double(newValue) }
                    ))
                    .frame(width: 300, height: 100)

            HStack{
                Text("Current Freq: \(tuner.result.currentFrequence, specifier: "%.2f") Hz")
                    .font(.system(size: 15))
                    .foregroundColor(.cyan)
                    .padding()
            }
            TuningButton(isTuning: $isTuning) { isTuning in
                if(!isTuning){
                    tuner.startTunning(config: currConfig)
                }else{
                    tuner.stopTunning()
                }
            }
//            HStack{
//                Button("Start Tunning") {
//                    tuner.startTunning(config: currConfig)
//                }
//                .padding()
//                .frame(maxWidth: .infinity)
//                .buttonBorderShape(ButtonBorderShape.roundedRectangle(radius: 12))
//                
//                Button("Stop Tunning") {
//                    tuner.stopTunning()
//                }
//                .padding()
//                .frame(maxWidth: .infinity)
//                .buttonBorderShape(ButtonBorderShape.roundedRectangle(radius: 12))
//                
//            }
        }
    }
}

struct TuningButton: View {
    @Binding var isTuning: Bool
    var toggleAction: (Bool)->Void
    var body: some View {
        VStack {
            // Tuning Button
            Button(action: {
                toggleAction(isTuning)
                isTuning.toggle()  // 切换 isTuning 的值
            }) {
                Text(isTuning ? "Stop Tuning" : "Start Tuning")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)  // 设置按钮宽度为自适应
                    .background(isTuning ? Color.red : Color.green)  // 不同状态不同颜色
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())  // 使用 PlainButtonStyle 来避免默认点击效果
            .padding()
        }
    }
}

struct RulerView: View {
    @Binding var value: Double

    // 刻度范围和步长
    let minValue = -150
    let maxValue = 150
    let step = 10

    // 生成刻度数组
    var tickValues: [Int] {
        stride(from: minValue, through: maxValue, by: step).map { Int($0) }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 刻度尺
            HStack(spacing: 0) {
                ForEach(tickValues, id: \.self) { tick in
                    VStack {
                        Rectangle()
                            .fill(tick % 10 == 0 ? Color.black : Color.gray)
                            .frame(width: 1, height: tick % 10 == 0 ? 20 : 10)
                        
                        if tick % 20 == 0 {
                            Text("\(tick)")
                                .font(.system(size: 8))
                                .offset(y: 0)
                        }
                    }
                    .frame(width: 20, alignment: .center)
                }
            }
            
            // 指针
            Rectangle()
                .fill(Color.red)
                .frame(width: 2, height: 40)
                .offset(x: CGFloat((value - Double(minValue)) / Double(maxValue - minValue) * 300) - 150)
                .animation(.easeInOut(duration: 0.5), value: value)
        }
    }
}


// 节奏面板视图
struct RhythmPanelView: View {
    var body: some View {
        VStack {
            Text("Rhythm Panel")
                .font(.title)
            // 在这里添加节奏面板的UI组件
        }
        .padding()
    }
}

// 弹奏面板视图
struct PlayPanelView: View {
    var body: some View {
        VStack {
            Text("Play Panel")
                .font(.title)
            // 在这里添加弹奏面板的UI组件
        }
        .padding()
    }
}

// 自定义按钮样式视图
struct SideMenuButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .frame(maxWidth: .infinity)   // 宽度拉满
                .padding()
                .background(isSelected ? Color.blue : Color.clear)  // 选中时背景为蓝色
                .foregroundColor(isSelected ? .white : .primary)   // 选中时字体为白色
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)  // 灰色边框
                )
        }
        .buttonStyle(PlainButtonStyle())  // 去掉默认的点击效果
    }
}
