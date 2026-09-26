package mmo.petfightnew.common.fightcontroller.fightinfopanel.tab
{
   import com.adobe.utils.ArrayUtil;
   import fl.containers.ScrollPane;
   import fl.controls.ScrollPolicy;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.material.hk.HKBuff;
   import mmo.interfaces.material.hk.HKHelp;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.common.FIP_EffectComponent;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.common.FIP_Info;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.config.FIP_ResConfig;
   import mmo.petfightnew.common.util.StatusUtil;
   
   public class FIP_Tab3 extends FIP_TabBase
   {
      
      private var _pbi:PetBriefInfo;
      
      private var _scrollPane:ScrollPane;
      
      private var _effectContainer:Sprite;
      
      private var _effectComponents:Array = [];
      
      public function FIP_Tab3(param1:FIP_Info, param2:int, param3:Function = null)
      {
         super(param1,param2,param3);
      }
      
      override protected function initComponents() : void
      {
         super.initComponents();
         this._effectContainer = this.getChild("mcEffectContainer");
         this._scrollPane = new ScrollPane();
         this._scrollPane.x = this._effectContainer.x;
         this._scrollPane.y = this._effectContainer.y;
         this._scrollPane.width = 340;
         this._scrollPane.height = 350;
         this._scrollPane.source = this._effectContainer;
         this._scrollPane.horizontalScrollPolicy = ScrollPolicy.OFF;
         this._view.addChild(this._scrollPane);
         FIP_ResConfig.changeSkin(this._scrollPane);
      }
      
      override protected function refreshView() : void
      {
         super.refreshView();
         this._pbi = _info.currSelectPbi();
         this.refreshEffect();
      }
      
      private function refreshEffect() : void
      {
         var _loc7_:FIP_EffectComponent = null;
         var _loc8_:Array = null;
         var _loc9_:RegExp = null;
         var _loc10_:int = 0;
         var _loc11_:Class = null;
         var _loc12_:MovieClip = null;
         var _loc13_:FIP_EffectComponent = null;
         var _loc1_:Array = [];
         var _loc2_:Vector.<HKBuff> = HKHelp.getActiveRareBuff(this._pbi.getHKIdArr(),this._pbi.getHKSlotLvArr());
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc1_.push({"hkBuff":_loc2_[_loc3_]});
            _loc3_++;
         }
         var _loc4_:String = this._pbi.status;
         if(_loc4_ != null && _loc4_ != "")
         {
            _loc8_ = _loc4_.split(",");
            _loc8_ = ArrayUtil.createUniqueCopy(_loc8_);
            _loc9_ = /suit_\d+_4/;
            _loc10_ = int(_loc8_.length - 1);
            while(_loc10_ >= 0)
            {
               if(StatusUtil.isToteStatus(_loc8_[_loc10_]))
               {
                  _loc1_.push({"st":_loc8_[_loc10_]});
               }
               if((_loc8_[_loc10_] as String).search(_loc9_) != -1)
               {
                  _loc1_.push({"st":_loc8_[_loc10_]});
               }
               _loc10_--;
            }
         }
         DisplayUtil.clearChildren(this._effectContainer);
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         while(_loc6_ < _loc1_.length)
         {
            _loc11_ = getDefinitionByName(FIP_ResConfig.EffectViewObj.clsName) as Class;
            _loc12_ = new _loc11_() as MovieClip;
            _loc12_.x = 0;
            _loc12_.y = _loc5_;
            _loc12_.name = "mcEffectView" + _loc6_;
            this._effectContainer.addChild(_loc12_);
            _loc13_ = this._effectComponents[_loc6_];
            if(_loc13_ == null)
            {
               _loc13_ = new FIP_EffectComponent();
               this._effectComponents[_loc6_] = _loc13_;
            }
            _loc13_.refresh(_loc12_,_loc1_[_loc6_]);
            _loc5_ += _loc13_.viewHeight + 5;
            _loc6_++;
         }
         this._scrollPane.refreshPane();
         for each(_loc7_ in this._effectComponents)
         {
            _loc7_.addTips();
         }
      }
      
      override public function dispose() : void
      {
         var _loc1_:FIP_EffectComponent = null;
         super.dispose();
         for each(_loc1_ in this._effectComponents)
         {
            _loc1_.dispose();
         }
         this._effectComponents = [];
      }
   }
}

