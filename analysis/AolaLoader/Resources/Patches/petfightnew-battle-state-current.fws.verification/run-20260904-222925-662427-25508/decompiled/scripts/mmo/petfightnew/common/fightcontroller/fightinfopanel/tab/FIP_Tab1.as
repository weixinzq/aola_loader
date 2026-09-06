package mmo.petfightnew.common.fightcontroller.fightinfopanel.tab
{
   import fl.containers.ScrollPane;
   import fl.controls.ScrollPolicy;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.data.SkillMap;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.common.FIP_Info;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.common.FIP_SkillComponent;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.config.FIP_ResConfig;
   
   public class FIP_Tab1 extends FIP_TabBase
   {
      
      private var _pbi:PetBriefInfo;
      
      private var _skillScrollPane:ScrollPane;
      
      private var _skillContainer:Sprite;
      
      private var _curSelectSkillIndex:int;
      
      private var _skillComponents:Array = [];
      
      private var _skillDesScrollPane:ScrollPane;
      
      private var _skillDesContainer:Sprite;
      
      private var _skills:Array = [];
      
      public function FIP_Tab1(param1:FIP_Info, param2:int, param3:Function = null)
      {
         super(param1,param2,param3);
      }
      
      override protected function initComponents() : void
      {
         super.initComponents();
         this._skillContainer = this.getChild("mcSkillContainer");
         this._skillScrollPane = new ScrollPane();
         this._skillScrollPane.x = this._skillContainer.x;
         this._skillScrollPane.y = this._skillContainer.y;
         this._skillScrollPane.width = this._skillContainer.width + 15;
         this._skillScrollPane.height = this._skillContainer.height;
         this._skillScrollPane.source = this._skillContainer;
         this._skillScrollPane.horizontalScrollPolicy = ScrollPolicy.OFF;
         this._view.addChild(this._skillScrollPane);
         FIP_ResConfig.changeSkin(this._skillScrollPane);
         this._skillDesContainer = this.getChild("mcSkillDesContainer");
         this._skillDesScrollPane = new ScrollPane();
         this._skillDesScrollPane.x = this._skillDesContainer.x;
         this._skillDesScrollPane.y = this._skillDesContainer.y;
         this._skillDesScrollPane.width = this._skillDesContainer.width + 15;
         this._skillDesScrollPane.height = this._skillDesContainer.height;
         this._skillDesScrollPane.source = this._skillDesContainer;
         this._skillDesScrollPane.horizontalScrollPolicy = ScrollPolicy.OFF;
         this._view.addChild(this._skillDesScrollPane);
         FIP_ResConfig.changeSkin(this._skillDesScrollPane);
      }
      
      override protected function refreshView() : void
      {
         super.refreshView();
         this._pbi = _info.currSelectPbi();
         this._skills = this._pbi.skills.concat();
         this.filterShenBingSkill(this._skills);
         this._curSelectSkillIndex = 0;
         this.refreshSkillView();
         this.refreshSkillSelectAndDes();
      }
      
      override protected function onClickButton(param1:DisplayObject) : void
      {
         var _loc2_:int = 0;
         super.onClickButton(param1);
         if(param1.name == "btnSkill")
         {
            _loc2_ = int(this.intelligentlyGetIndex(param1));
            if(this._curSelectSkillIndex != _loc2_)
            {
               this._curSelectSkillIndex = _loc2_;
               this.refreshSkillSelectAndDes();
            }
         }
      }
      
      private function refreshSkillView() : void
      {
         var _loc3_:Class = null;
         var _loc4_:MovieClip = null;
         var _loc5_:FIP_SkillComponent = null;
         var _loc6_:FIP_SkillComponent = null;
         DisplayUtil.clearChildren(this._skillContainer);
         var _loc1_:int = 0;
         while(_loc1_ < this._skills.length)
         {
            _loc3_ = getDefinitionByName(FIP_ResConfig.SkillViewObj.clsName) as Class;
            _loc4_ = new _loc3_() as MovieClip;
            _loc4_.x = _loc1_ % 2 * 168;
            _loc4_.y = Math.floor(_loc1_ / 2) * 70 + 5;
            _loc4_.name = "mcSkillView" + _loc1_;
            this._skillContainer.addChild(_loc4_);
            _loc5_ = this._skillComponents[_loc1_];
            if(_loc5_ == null)
            {
               _loc5_ = new FIP_SkillComponent();
               this._skillComponents[_loc1_] = _loc5_;
            }
            _loc5_.refresh(_loc4_,this._skills[_loc1_]);
            _loc1_++;
         }
         this._skillScrollPane.refreshPane();
         var _loc2_:int = 0;
         while(_loc2_ < this._skills.length)
         {
            _loc6_ = this._skillComponents[_loc2_];
            _loc6_.addTips(this._skills[_loc2_]);
            _loc2_++;
         }
      }
      
      private function refreshSkillSelectAndDes() : void
      {
         var _loc1_:int = 0;
         while(_loc1_ < this._skills.length)
         {
            (this._skillComponents[_loc1_] as FIP_SkillComponent).refreshSelect(this._curSelectSkillIndex == _loc1_);
            _loc1_++;
         }
         var _loc2_:SkillInfo = this._skills[this._curSelectSkillIndex];
         var _loc3_:PMSkill = _pmSvr.customData.pmSkillMap.getSkill(_loc2_.id);
         var _loc4_:int = int(_loc3_.attackType);
         var _loc5_:String = "普通攻击";
         if(_loc4_ == 1)
         {
            _loc5_ = "特殊攻击";
         }
         else if(_loc4_ == 2)
         {
            _loc5_ = "属性攻击";
         }
         this.setText("txtSkillAttackType",_loc5_);
         this.setText("txtSkillTarget",SkillMap.getHitTargetChinese(_loc3_.hitTaget));
         var _loc6_:int = _loc3_.hitRate <= 0 ? 100 : int(_loc3_.hitRate);
         this.setText("txtHitRate",_loc6_ + "%");
         DisplayUtil.clearChildren(this._skillDesContainer);
         var _loc7_:TextField = new TextField();
         _loc7_.width = 300;
         _loc7_.wordWrap = true;
         _loc7_.selectable = false;
         _loc7_.textColor = 7199487;
         _loc7_.htmlText = _loc3_.clientDesc;
         _loc7_.setTextFormat(FIP_ResConfig.createTextFormat(12,2));
         this._skillDesContainer.addChild(_loc7_);
         this._skillDesScrollPane.refreshPane();
      }
      
      private function filterShenBingSkill(param1:Array) : void
      {
         var _loc3_:PMSkill = null;
         var _loc2_:int = int(param1.length - 1);
         while(_loc2_ >= 0)
         {
            _loc3_ = this._pmSvr.customData.pmSkillMap.getSkill(param1[_loc2_].id);
            if(_loc3_.getSkillType() == PMSkillTypes.GQ_SHENBING_PASSIVE)
            {
               param1.splice(_loc2_,1);
            }
            _loc2_--;
         }
      }
      
      override public function dispose() : void
      {
         var _loc1_:FIP_SkillComponent = null;
         super.dispose();
         for each(_loc1_ in this._skillComponents)
         {
            _loc1_.dispose();
         }
         this._skillComponents = [];
      }
   }
}

