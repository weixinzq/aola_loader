package mmo.petfightnew.common.fightcontroller.fightinfopanel.tab
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.config.ConfigReader;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.GQGuangJinSkillParse;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.data.PMAttributeMap;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.common.FIP_Info;
   import mmo.petfightnew.common.panel.hp.NewHPBar;
   import mmo.petfightnew.common.util.GQPetHelper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.attribute.AttributeIconHandler;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   public class FIP_Tab0 extends FIP_TabBase
   {
      
      private static const TotalAttrIconNum:int = 12;
      
      private static const TotalSpAttrType:int = 8;
      
      private var _hpBar:NewHPBar;
      
      private var _pbi:PetBriefInfo;
      
      private var _targetAttrs:Array = [];
      
      private var _attributeIcons:Array = [];
      
      public function FIP_Tab0(param1:FIP_Info, param2:int, param3:Function = null)
      {
         super(param1,param2,param3);
      }
      
      override protected function initComponents() : void
      {
         super.initComponents();
      }
      
      override protected function refreshView() : void
      {
         super.refreshView();
         this._pbi = _info.currSelectPbi();
         this.setFrame("",_info.isSelectMe ? 1 : 2);
         this.setText("txtLv","[LV." + this._pbi.level + "]");
         this.setText("txtName",this._pbi.name);
         var _loc1_:MovieClip = this.getChild("mcHP") as MovieClip;
         this._hpBar = new NewHPBar(_loc1_,true);
         this._hpBar.update(this._pbi);
         this.setVisible(["mcHP","mcHp","txtHp"],_info.isSelectMe);
         this.refreshGQSoul();
         this.refreshAttrIcon();
         this.refreshSpAttrLv();
         this.refreshBaseValue();
         this.refreshDebugCurrValue();
      }
      
      private function refreshGQSoul() : void
      {
         var _loc8_:int = 0;
         var _loc9_:MovieClip = null;
         var _loc1_:MovieClip = this.getChild("mcGQSoulContainer") as MovieClip;
         _loc1_.mouseEnabled = _loc1_.mouseChildren = false;
         if(!GQPetHelper.checkIsGQPet(this._pbi.raceId))
         {
            _loc1_.visible = false;
            return;
         }
         _loc1_.visible = true;
         var _loc2_:PMData = _pmSvr.getOperationPM(this._pbi.raceId).pmData;
         var _loc3_:int = int(_loc2_.maxGQSoulNum);
         _loc1_.gotoAndStop(_loc3_ - 4);
         var _loc4_:MovieClip = _loc1_.getChildByName("mcsouls") as MovieClip;
         var _loc5_:int = 0;
         while(_loc5_ < _loc3_)
         {
            ActComHelper.setMcFrame(_loc4_,"mcSoul" + _loc5_,_loc5_ < this._pbi.curGQSoulNum ? 1 : 2);
            _loc5_++;
         }
         var _loc6_:MovieClip = _loc4_.getChildByName("mcSoulNum") as MovieClip;
         ArtNumberManager.setNumber([_loc6_],this._pbi.curGQSoulNum);
         var _loc7_:MovieClip = _loc4_.getChildByName("mcGuangjinLock") as MovieClip;
         if(GQPetType.isGuangJin(_loc2_.getGQType()))
         {
            _loc7_.visible = true;
            _loc8_ = 0;
            while(_loc8_ < GQGuangJinSkillParse.MaxCanUseTimes)
            {
               _loc9_ = _loc7_.getChildByName("mcLock" + _loc8_) as MovieClip;
               _loc9_.visible = GQGuangJinSkillParse.getGuangJinSkillData(this._pbi.raceId).getUseSkillTimes(this._pbi) > _loc8_;
               _loc8_++;
            }
         }
         else
         {
            _loc7_.visible = false;
         }
      }
      
      private function refreshAttrIcon() : void
      {
         var _loc1_:Array = null;
         var _loc5_:Number = NaN;
         var _loc6_:int = 0;
         var _loc7_:MovieClip = null;
         var _loc8_:AttributeIconHandler = null;
         var _loc9_:MovieClip = null;
         this._targetAttrs = [];
         if(_pmSvr.getOperationPM(this._pbi.raceId).pmData.pmAttribute == _pmSvr.getOperationPM(this._pbi.raceId).pmData.pmAttribute2)
         {
            _loc1_ = [_pmSvr.getOperationPM(this._pbi.raceId).pmData.pmAttribute];
         }
         else
         {
            _loc1_ = [_pmSvr.getOperationPM(this._pbi.raceId).pmData.pmAttribute,_pmSvr.getOperationPM(this._pbi.raceId).pmData.pmAttribute2];
         }
         var _loc2_:Array = PMAttributeMap.getAllSuperAttris();
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc5_ = 1;
            _loc6_ = 0;
            while(_loc6_ < _loc1_.length)
            {
               _loc5_ *= _pmSvr.customData.pmAttDefMap.getMultipleValueByIndex(_loc2_[_loc3_],_loc1_[_loc6_]);
               _loc6_++;
            }
            if(_loc5_ < 0.99 || _loc5_ > 1.01)
            {
               this._targetAttrs.push({
                  "attrId":_loc2_[_loc3_],
                  "multipleValue":_loc5_
               });
            }
            _loc3_++;
         }
         this._targetAttrs.sortOn("multipleValue",Array.NUMERIC | Array.DESCENDING);
         var _loc4_:int = 0;
         while(_loc4_ < TotalAttrIconNum)
         {
            _loc7_ = this.getChild("mcAttrIconContainer" + _loc4_);
            if(_loc4_ < this._targetAttrs.length)
            {
               _loc7_.visible = true;
               _loc8_ = this._attributeIcons[_loc4_];
               if(_loc8_ == null)
               {
                  _loc8_ = new AttributeIconHandler(this.getChild([_loc7_,"mcAttrIcon"]));
                  this._attributeIcons[_loc4_] = _loc8_;
               }
               _loc8_.setIcon(this._targetAttrs[_loc4_]["attrId"]);
               _loc9_ = this.getChild([_loc7_,"mcMultipValue"]);
               if(this._targetAttrs[_loc4_]["multipleValue"] > 1)
               {
                  _loc9_.gotoAndStop(1);
               }
               else
               {
                  _loc9_.gotoAndStop(2);
               }
               this.setText([_loc9_,"txtAttrMultiple"],Number(this._targetAttrs[_loc4_]["multipleValue"]).toFixed(1) + "倍");
            }
            else
            {
               _loc7_.visible = false;
            }
            _loc4_++;
         }
      }
      
      private function refreshSpAttrLv() : void
      {
         var _loc5_:Sprite = null;
         var _loc6_:MovieClip = null;
         var _loc7_:MovieClip = null;
         var _loc1_:int = 0;
         var _loc2_:Array = this._pbi.attributeLevelArr;
         var _loc3_:int = 0;
         while(_loc3_ < TotalSpAttrType)
         {
            _loc5_ = this.getChild("spAtt" + _loc1_) as Sprite;
            if(_loc2_[_loc3_] != 0)
            {
               _loc5_.visible = true;
               _loc6_ = _loc5_.getChildByName("mcDes") as MovieClip;
               _loc6_.gotoAndStop(_loc3_ + 1);
               _loc7_ = _loc5_.getChildByName("mcState") as MovieClip;
               _loc7_.gotoAndStop(_loc2_[_loc3_] > 0 ? 1 : 2);
               this.setText([_loc7_,"txtNum"],Math.abs(_loc2_[_loc3_]));
               _loc1_++;
            }
            _loc3_++;
         }
         var _loc4_:int = _loc1_;
         while(_loc4_ < TotalSpAttrType)
         {
            _loc5_ = this.getChild("spAtt" + _loc4_) as Sprite;
            _loc5_.visible = false;
            _loc4_++;
         }
      }
      
      private function refreshBaseValue() : void
      {
         var _loc2_:int = 0;
         var _loc1_:Array = [this._pbi.maxBaseAbility.attack,this._pbi.maxBaseAbility.specialAttack,this._pbi.maxBaseAbility.defence,this._pbi.maxBaseAbility.hp,this._pbi.maxBaseAbility.speed];
         if(_info.isSelectMe)
         {
            _loc2_ = 0;
            while(_loc2_ < _loc1_.length)
            {
               this.setText("txtBaseValue" + _loc2_,_loc1_[_loc2_]);
               _loc2_++;
            }
         }
      }
      
      private function refreshDebugCurrValue() : void
      {
         var _loc1_:Array = null;
         var _loc2_:int = 0;
         if(ConfigReader.instance.debug)
         {
            this.setVisible("mcDebugCurr",true);
            _loc1_ = [this._pbi.getCurrAbility().attack,this._pbi.getCurrAbility().specialAttack,this._pbi.getCurrAbility().defence,this._pbi.getCurrAbility().hp,this._pbi.getCurrAbility().speed,this._pbi.maxHp];
            _loc2_ = 0;
            while(_loc2_ < _loc1_.length)
            {
               this.setText(["mcDebugCurr","txtCurrValue" + _loc2_],_loc1_[_loc2_]);
               _loc2_++;
            }
         }
         else
         {
            this.setVisible("mcDebugCurr",false);
         }
      }
   }
}

