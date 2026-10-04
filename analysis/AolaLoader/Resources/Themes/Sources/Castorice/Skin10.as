package aola.theme.t10.mmo.controlv2.controlbarskin.skin
{
   import aola.theme.t10.mmo.control.ActionPanel;
   import aola.theme.t10.mmo.control.BlueIcon;
   import aola.theme.t10.mmo.control.HistoryPanelV2;
   import aola.theme.t10.mmo.control.RestGameTime;
   import aola.theme.t10.mmo.control.TalkBar;
   import aola.theme.t10.mmo.control.pause.PauseBtnMC;
   import aola.theme.t10.mmo.control.pet.PetIcon;
   import aola.theme.t10.mmo.control.player.PlayerInfo;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.Graphics;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.events.Event;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getTimer;

   public dynamic class Skin10 extends MovieClip
   {
      private static const ORNAMENT_OFFSET_Y:Number = 33;

      public var btnAction:SimpleButton;
      public var btnMap:SimpleButton;
      public var btnSetSkin:SimpleButton;
      public var btnShootPlace:SimpleButton;
      public var btnonlinecustomericon:SimpleButton;
      public var mcBaiXingVip:MovieClip;
      public var mcBlueGem:BlueIcon;
      public var mcNFA:MovieClip;
      public var mcPauseBtn:PauseBtnMC;
      public var mcPetIcon:PetIcon;
      public var mcPlayerInfo:PlayerInfo;
      public var mcRedPackage:MovieClip;
      public var mcRestGameTime:RestGameTime;
      public var mcShouChong:MovieClip;
      public var mcWeeklyTask:MovieClip;
      public var mcaolamasterredtips:MovieClip;
      public var mcleftdownbtn:MovieClip;
      public var mcleftdownfloatbar:MovieClip;
      public var mcrightdownbtn:MovieClip;
      public var mcrightdownfloatbar:MovieClip;
      public var mcrightupbtn:MovieClip;
      public var mcrightupfloatbar:MovieClip;
      public var mctalkbar:TalkBar;
      public var pnlAction:ActionPanel;
      public var pnlHistory:HistoryPanelV2;
      public var aolaOrnament:DisplayObject;
      public var aolaStyleSources:MovieClip;

      private var _effects:Sprite;
      private var _wings:Array = [];
      private var _elapsed:Number = 0;
      private var _lastTime:int = 0;
      private var _listening:Boolean = false;
      private var _mouseLayer:DisplayObjectContainer;
      private var _mouseLayerEnabled:Boolean;
      private var _themeStage:Stage;
      private var _styleData:Object = {};
      private var _styledButtons:Dictionary = new Dictionary(true);
      private var _teamPanels:Array = [];
      private var _notifyIcons:Dictionary = new Dictionary(true);

      public function Skin10()
      {
         super();
         stop();
         aolaStyleSources.visible = false;
         aolaStyleSources.mouseEnabled = false;
         aolaStyleSources.mouseChildren = false;
         // The account service keeps updating the real viewer inside playerhead.
         var head:DisplayObject = mcPlayerInfo.getChildByName("playerhead");
         head.x = 16.3;
         head.y = 65.7;
         head.scaleX = head.scaleY = 0.72;
         var headMask:Sprite = new Sprite();
         headMask.mouseEnabled = headMask.mouseChildren = false;
         headMask.graphics.beginFill(0xFFFFFF);
         headMask.graphics.drawCircle(42.8,92.2,26.5);
         headMask.graphics.endFill();
         mcPlayerInfo.addChild(headMask);
         head.mask = headMask;
         // Artwork also contributes to ancestor hit geometry; only children are interactive.
         mouseEnabled = false;
         // mcBlueGem/btnblue and the original hover menus keep their mouseChildren policy.
         var ornament:Sprite = new Sprite();
         ornament.mouseEnabled = false;
         ornament.mouseChildren = false;
         // The ornament's horizontal lower edge is the viewport bottom; no extra solid strip.
         aolaOrnament.y += ORNAMENT_OFFSET_Y;
         ornament.addChild(aolaOrnament);
         addChildAt(ornament,0);
         _effects = new Sprite();
         _effects.mouseEnabled = false;
         _effects.mouseChildren = false;
         addChild(_effects);
         for(var i:int = 0; i < 6; i++)
         {
            var wing:Sprite = new Sprite();
            var g:Graphics = wing.graphics;
            g.beginFill(0xA994D1,0.85);
            g.moveTo(0,0);
            g.curveTo(-14,-20,-13,-4);
            g.curveTo(-20,9,-2,3);
            g.lineTo(0,7);
            g.lineTo(2,3);
            g.curveTo(20,9,13,-4);
            g.curveTo(14,-20,0,0);
            g.endFill();
            _effects.addChild(wing);
            _wings.push(wing);
         }
         addEventListener(Event.ADDED_TO_STAGE,onThemeAdded);
         addEventListener(Event.REMOVED_FROM_STAGE,onThemeRemoved);
         drawEffects();
         if(stage != null) onThemeAdded(null);
      }

      private function onThemeAdded(event:Event) : void
      {
         if(_listening) return;
         // The skin's ControlBarSkinBase wrapper must not catch decoration-only hits either.
         parent.mouseEnabled = false;
         // BaseControl is a sibling above BaseScene, where the game listens for walking clicks.
         // Keep its children interactive, and restore its own policy when this theme leaves.
         _mouseLayer = parent.parent;
         _mouseLayerEnabled = _mouseLayer.mouseEnabled;
         _mouseLayer.mouseEnabled = false;
         _themeStage = stage;
         _themeStage.addEventListener(Event.ADDED,onExternalAdded,true);
         // These objects may already exist when a cached theme is shown again.
         scanExternal(_themeStage);
         _lastTime = getTimer();
         addEventListener(Event.ENTER_FRAME,onThemeFrame);
         _listening = true;
      }

      private function onThemeRemoved(event:Event) : void
      {
         _themeStage.removeEventListener(Event.ADDED,onExternalAdded,true);
         _themeStage = null;
         for each(var panel:MovieClip in _teamPanels)
            panel.removeEventListener(Event.ADDED,onTeamChildAdded);
         _teamPanels = [];
         for(var button:Object in _styledButtons)
         {
            var states:Object = _styledButtons[button];
            button.upState = states.up;
            button.overState = states.over;
            button.downState = states.down;
         }
         _styledButtons = new Dictionary(true);
         for(var icon:Object in _notifyIcons)
         {
            icon.removeEventListener(Event.FRAME_CONSTRUCTED,onNotifyFrame);
            var record:Object = _notifyIcons[icon];
            icon.removeChild(record.art);
            for(var child:Object in record.hidden) child.visible = record.hidden[child];
         }
         _notifyIcons = new Dictionary(true);
         _mouseLayer.mouseEnabled = _mouseLayerEnabled;
         _mouseLayer = null;
         removeEventListener(Event.ENTER_FRAME,onThemeFrame);
         _listening = false;
         _lastTime = 0;
      }

      private function onExternalAdded(event:Event) : void
      {
         styleExternal(event.target as DisplayObject);
      }

      private function scanExternal(node:DisplayObject) : void
      {
         styleExternal(node);
         if(node is DisplayObjectContainer)
         {
            var container:DisplayObjectContainer = node as DisplayObjectContainer;
            for(var i:int = 0; i < container.numChildren; i++) scanExternal(container.getChildAt(i));
         }
      }

      private function styleExternal(node:DisplayObject) : void
      {
         var kind:String = getQualifiedClassName(node);
         if(kind == "mmo.team.teamservice::TeamButton" && node.parent == mcrightdownfloatbar)
         {
            var team:MovieClip = node as MovieClip;
            var panel:MovieClip = team.btnteampanel;
            if(_teamPanels.indexOf(panel) >= 0) return;
            _teamPanels.push(panel);
            // The original service removes this panel until hover, and changes its frames.
            panel.addEventListener(Event.ADDED,onTeamChildAdded);
            styleTeamTree(team);
            styleTeamTree(panel);
         }
         else if(kind == "mmo.notifyview::ActNotifyIcon" && _notifyIcons[node] == null)
         {
            var icon:MovieClip = node as MovieClip;
            var art:Bitmap = makeState("message_up",icon.getBounds(icon));
            _notifyIcons[icon] = {art:art,hidden:new Dictionary(true),frame:0};
            icon.addChild(art);
            icon.addEventListener(Event.FRAME_CONSTRUCTED,onNotifyFrame);
            styleNotify(icon);
         }
      }

      private function onTeamChildAdded(event:Event) : void
      {
         styleTeamTree(event.target as DisplayObject);
      }

      private function styleTeamTree(node:DisplayObject) : void
      {
         if(node is SimpleButton && _styledButtons[node] == null)
         {
            var key:String = node.name == "btnTeam" ? "team" :
               node.name == "btn_all" ? "scene" : node.name == "btnactteam" ? "activity" : null;
            if(key != null)
            {
               var button:SimpleButton = node as SimpleButton;
               _styledButtons[button] = {up:button.upState,over:button.overState,down:button.downState};
               var bounds:Rectangle = button.upState.getBounds(button.upState);
               button.upState = makeState(key + "_up",bounds);
               button.overState = makeState(key + "_over",bounds);
               button.downState = makeState(key + "_down",bounds);
               // hitTestState, instance name, enabled state and every original listener stay owned by Flash.
            }
         }
         if(node is DisplayObjectContainer)
         {
            var container:DisplayObjectContainer = node as DisplayObjectContainer;
            for(var i:int = 0; i < container.numChildren; i++) styleTeamTree(container.getChildAt(i));
         }
      }

      private function makeState(key:String,bounds:Rectangle) : Bitmap
      {
         var data:BitmapData = _styleData[key] as BitmapData;
         if(data == null)
         {
            var source:DisplayObject = aolaStyleSources.getChildByName(key);
            var box:Rectangle = source.getBounds(source);
            data = new BitmapData(Math.ceil(box.width * 2),Math.ceil(box.height * 2),true,0);
            var transform:Matrix = new Matrix(2,0,0,2,-box.x * 2,-box.y * 2);
            data.draw(source,transform,null,null,null,true);
            _styleData[key] = data;
         }
         var bitmap:Bitmap = new Bitmap(data,"auto",true);
         bitmap.x = bounds.x;
         bitmap.y = bounds.y;
         bitmap.scaleX = bounds.width / data.width;
         bitmap.scaleY = bounds.height / data.height;
         return bitmap;
      }

      private function onNotifyFrame(event:Event) : void
      {
         styleNotify(event.currentTarget as MovieClip);
      }

      private function styleNotify(icon:MovieClip) : void
      {
         var record:Object = _notifyIcons[icon];
         if(record.frame == icon.currentFrame) return;
         record.frame = icon.currentFrame;
         for(var i:int = 0; i < icon.numChildren; i++)
         {
            var child:DisplayObject = icon.getChildAt(i);
            if(child == record.art || child.name == "mcnum") continue;
            if(record.hidden[child] === undefined) record.hidden[child] = child.visible;
            child.visible = false;
         }
         icon.setChildIndex(record.art,0);
         // The original mcnum and seven-frame unread/default-tab logic remain untouched.
      }

      private function onThemeFrame(event:Event) : void
      {
         var now:int = getTimer();
         var node:DisplayObject = this;
         var shown:Boolean = true;
         while(node != null)
         {
            if(!node.visible) shown = false;
            node = node.parent;
         }
         if(shown)
         {
            _elapsed = (_elapsed + (now - _lastTime) / 1000) % 8;
            drawEffects();
         }
         // Hidden ancestors pause phase, rather than accumulating elapsed time.
         _lastTime = now;
      }

      private function drawEffects() : void
      {
         var phase:Number = _elapsed * Math.PI / 4;
         var positions:Array = [[18,445,8,11],[107,444,8,12],[368,475,18,9],
            [607,473,14,10],[818,478,12,9],[942,457,10,12]];
         for(var i:int = 0; i < 6; i++)
         {
            var wing:Sprite = _wings[i];
            var p:Array = positions[i];
            wing.x = p[0] + p[2] * Math.cos(phase + i * 0.9) + 8.8;
            wing.y = p[1] + p[3] * Math.sin(phase + i * 0.9) - 480.4 + ORNAMENT_OFFSET_Y;
            wing.scaleX = (0.62 + 0.32 * Math.cos(phase * 24 + i)) * 0.85;
            wing.scaleY = 0.85;
            wing.rotation = 15 * Math.sin(phase + i);
         }
         var g:Graphics = _effects.graphics;
         g.clear();
         // Two small travelling light strokes, no full-stage filters or audio.
         for(i = 0; i < 2; i++)
         {
            var x:Number = (i == 0 ? 129 : 588) + ((_elapsed / 8 + i * .5) % 1) * 250;
            var y:Number = (i == 0 ? 485 : 480) + ORNAMENT_OFFSET_Y;
            g.lineStyle(1.4,0xA994D1,0.55);
            g.moveTo(x + 8.8,y - 480.4);
            g.curveTo(x + 21,y - 485.4,x + 35,y - 480.4);
         }
         for(i = 0; i < 10; i++)
         {
            g.beginFill(0xEAE6F3,0.2 + 0.15 * Math.sin(phase + i));
            g.drawCircle(163.8 + i * 68 + 8 * Math.cos(phase + i),
               0.6 + 5 * Math.sin(phase + i * .7) + ORNAMENT_OFFSET_Y,0.8);
            g.endFill();
         }
         // A short silver glint travels around the account frame in the same 8s cycle.
         var edge:Number = _elapsed / 8 * 656;
         g.lineStyle(1.1,0xEAE6F3,0.5);
         if(edge < 253)
         {
            g.moveTo(edge + 8.8,-478.4);
            g.lineTo(Math.min(edge + 18,253) + 8.8,-478.4);
         }
         else if(edge < 329)
         {
            g.moveTo(261.8,edge - 253 - 480.4);
            g.lineTo(261.8,Math.min(edge - 235,76) - 480.4);
         }
         else if(edge < 582)
         {
            g.moveTo(590.8 - edge,-405.4);
            g.lineTo(Math.max(572 - edge,0) + 8.8,-405.4);
         }
         else
         {
            g.moveTo(9.8,658 - edge - 480.4);
            g.lineTo(9.8,Math.max(640 - edge,0) - 480.4);
         }
      }
   }
}
