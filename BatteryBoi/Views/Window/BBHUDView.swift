//
//  BBHUDView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/12/23.
//

import SwiftUI

enum HUDProgressLayout {
    case center
    case trailing
    
}

enum HUDState:Equatable {
    case hidden
    case progress
    case revealed
    case detailed
    case dismissed
    
    var visible:Bool {
        switch self {
            case .detailed : return true
            case .revealed : return true
            default : return false
            
        }
        
    }
    
    var mask:AnimationObject? {
        if self == .revealed {
            return .init([
                .init(0.6, delay: 0.2, easing: .bounce, width: 120, height: 120, blur: 0, radius: 66),
                .init(2.9, easing: .bounce, width: 400, height: 120, blur: 0, radius: 66)], id: "initial")
            
        }
        else if self == .detailed {
            return .init([.init(0.0, easing: .bounce, width: 410, height: 220, radius: 42)], id:"expand_out")
            
        }
        else if self == .dismissed {
            return .init([
                .init(0.2, easing: .bounce, width: 400, height: 120, radius: 66),
                .init(0.2, easing: .easeout, width: 120, height: 120, radius: 66),
                .init(0.3, delay:1.0, easing: .bounce, width: 40, height: 40, opacity: 0, radius: 66)], id: "expand_close")

        }
        
        return nil
        
    }
    
    var glow:AnimationObject? {
        if self == .revealed {
            return .init([
                .init(0.03, easing: .easeout, opacity: 0.0, scale: 0.2),
                .init(0.4, easing: .bounce, opacity: 0.4, scale: 1.9),
                .init(0.4, easing: .easein, opacity: 0.0, blur:2.0)])
            
        }
        else if self == .dismissed {
            return .init([
                .init(0.03, easing: .easeout, opacity: 0.0, scale: 0.2),
                .init(0.4, easing: .easein, opacity: 0.6, scale:1.4),
                .init(0.2, easing: .bounce, opacity: 0.0, scale: 0.2)])
            
        }
        
        return nil

    }
    
    var progress:AnimationObject? {
        if self == .revealed {
            return .init([
                .init(0.2, easing: .bounce, opacity: 0.0, blur:0.0, scale: 0.8),
                .init(0.4, delay: 0.4, easing: .easeout, opacity: 1.0, scale:1.0)])
            
        }
        else if self == .dismissed {
            return .init([.init(0.6, easing: .bounce, opacity: 0.0, blur:12.0, scale: 0.9)])
            
        }

        return nil
        
    }
    
    var container:AnimationObject? {
        if self == .detailed {
            return .init([.init(0.4, easing: .easeout, padding:.init(top:24, bottom:16))], id:"hud_expand")
            
        }
        else if self == .dismissed {
            return .init([.init(0.6, delay: 0.2, easing: .easeout, opacity: 0.0, blur: 5.0)])

        }
        
        return nil

    }


}

struct HUDSummary: View {
    @EnvironmentObject var stats:StatsManager
    @EnvironmentObject var updates:UpdateManager
    @EnvironmentObject var window:WindowManager

    @State private var title = ""
    @State private var subtitle = ""
    @State private var visible:Bool = false
    
    var body: some View {
        HStack(alignment: .center) {
            ModalIcon()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                ViewMarkdown($subtitle)
                
                if self.updates.available != nil {
                    UpdatePromptView()
                    
                }
                
            }
            
            Spacer()
            
        }
        .blur(radius: self.visible ? 0.0 : 4.0)
        .opacity(self.visible ? 1.0 : 0.0)
        .onAppear() {
            self.title = self.stats.title
            self.subtitle = self.stats.subtitle
            self.visible == WindowManager.shared.state.visible

        }
        .onChange(of: self.stats.title) { newValue in
            self.title = newValue

        }
        .onChange(of: self.stats.subtitle) { newValue in
            self.subtitle = newValue

        }
        .onChange(of: window.state, perform: { newValue in
            withAnimation(Animation.easeOut(duration: 0.6).delay(self.visible == false ? 0.9 : 0.0)) {
                self.visible = newValue.visible

            }
          
        })
        
    }
    
}

struct HUDContainer: View {
    @EnvironmentObject var battery:BatteryManager
    @EnvironmentObject var manager:WindowManager
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var namespace:Namespace.ID
    @State private var animation:AnimationState = .waiting
    
    @Binding private var progress:HUDProgressLayout

    init(animation:Namespace.ID, progress:Binding<HUDProgressLayout>) {
        self._namespace = State(initialValue: animation)
        self._timeline = State(initialValue: .init([]))
        self._progress = progress

    }
    
    var body: some View {
        HStack(alignment: .center) {
            HUDSummary()

            if self.progress == .trailing {
                HUDProgress().matchedGeometryEffect(id: "progress", in: self.namespace)
                
            }
            
        }
        .timeline($timeline ,state: $animation)
        .padding(.leading, 20)
        .padding(.trailing, 10)
        .onAppear() {
            if let animation = window.state.container {
                self.timeline = animation
                
            }
            
        }
        .onChange(of: window.state, perform: { newValue in
            if let animation = newValue.container {
                self.timeline = animation
                
            }
            
            if newValue == .revealed {
                withAnimation(Animation.easeOut.delay(0.75)) {
                    self.progress = .trailing
                    
                }

            }
          
        })
        
    }
    
}

struct HUDMaskView: View {
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var animation:AnimationState = .waiting

    var keyframes = Array<AnimationKeyframeObject>()
    
    init() {
        self._timeline = State(initialValue: .init([]))
        
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .timeline($timeline, state: $animation)
                .frame(width: 20, height: 20)
            
        }
        .opacity(window.opacity)
        .onAppear() {
            if let animation = window.state.mask {
                self.timeline = animation
                
            }
          
        }
        .onChange(of: window.state, perform: { newValue in
            if let animation = newValue.mask {
                self.timeline = animation
                
            }
          
        })
        
    }

}

struct HUDGlow: View {
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var animation:AnimationState = .waiting

    init() {
        self._timeline = State(initialValue: .init([]))

    }
    
    var body: some View {
        Circle()
            .fill(Color("BatteryBackground"))
            .frame(width: 80, height: 80)
            .timeline($timeline, state: $animation)
            .onAppear() {
                if let animation = window.state.glow {
                    self.timeline = animation
                    
                }
              
            }
            .onChange(of: window.state, perform: { newValue in
                if let animation = newValue.glow {
                    self.timeline = animation
                    
                }
              
            })

    }
    
}

struct HUDProgress: View {
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var animation:AnimationState = .waiting

    init() {
        self._timeline = State(initialValue: .init([]))

    }
    
    var body: some View {
        RadialProgressContainer(true)
            .timeline($timeline, state: $animation)
            .onAppear() {
                if let animation = window.state.progress {
                    self.timeline = animation
                    
                }
              
            }
            .onChange(of: window.state, perform: { newValue in
                if let animation = newValue.progress {
                    self.timeline = animation
                    
                }
                
            })
        
    }
    
}

struct HUDView: View {
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var animation:AnimationState = .waiting
    @State private var progress:HUDProgressLayout = .center

    @Namespace private var namespace

    init() {
        self._timeline = State(initialValue: .init([]))

    }
    
    var body: some View {
        ZStack(alignment: .center) {
            VStack {
                if self.window.state == .detailed {
                    HUDContainer(animation: namespace, progress: $progress)
                        .matchedGeometryEffect(id: "hud", in: self.namespace)
                    
                    ModalMenuView()
                                        
                }
                else {
                    HUDContainer(animation: namespace, progress: $progress)
                        .matchedGeometryEffect(id: "hud", in: self.namespace)

                }
                
            }
               
            if progress == .center {
                HUDProgress().matchedGeometryEffect(id: "progress", in: self.namespace)

            }
            
        }
        .frame(width: 410, height: 240)
        .background(Color("BatteryBackground"))
        .timeline($timeline, state: $animation)
        .mask(
            HUDMaskView()

        )
        .background(
            HUDGlow()
            
        )
        .onHover(perform: { hover in
            self.window.hover = hover
            
        })
        
    }
    
}


