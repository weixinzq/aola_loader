package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.common.utils.tips.TipsType;
   import mmo.interfaces.pet.data.IPetBattleEffDataService;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.TrainingFightTypes;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.panel.be.BEPanel;
   import mmo.petfightnew.common.util.StatusUtil;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol100")]
   public class HpBar extends Sprite
   {
      
      public var hp:MovieClip;
      
      public var spBE:BEPanel;
      
      public var txtInfo:TextField;
      
      private var locaId:int;
      
      private var lingshouRealitySlotId:int = -1;
      
      private var statuses:Array;
      
      private var spe:Sprite;
      
      private var icons:Array;
      
      private const STATE_LEN:int = 8;
      
      private const HP_LEN:int = 68;
      
      public function HpBar(param1:PetBriefInfo, param2:int)
      {
         super();
         this.locaId = param2;
         var _loc3_:int = FightData.instance.getSlotId(this.locaId);
         var _loc4_:PlayerBattleInfo = FightData.instance.playerInfo[_loc3_];
         this.lingshouRealitySlotId = _loc4_.lingshouRealitySlotId;
         this.spe = this.getChildByName("spBE") as Sprite;
         this.spe.mouseChildren = false;
         this.spe.mouseEnabled = false;
         this.initStateIcons();
         this.setView(param1);
         if(!FightData.instance.isMySide(this.locaId) || FightController.instance.isReplay)
         {
            this.addAttribute(param1);
         }
      }
      
      public function setStatus(param1:String) : void
      {
         var _loc2_:int = 0;
         var _loc6_:MovieClip = null;
         this.clearStatus();
         if(param1 == null || param1 == "")
         {
            return;
         }
         this.statuses = param1.split(",");
         var _loc3_:int = int(this.statuses.length);
         var _loc4_:int = -1;
         var _loc5_:int = 0;
         while(_loc5_ < _loc3_)
         {
            _loc2_ = StatusUtil.getFrame(this.statuses[_loc5_]);
            if(_loc2_ != 0)
            {
               _loc4_++;
               _loc6_ = this.icons[_loc4_] as MovieClip;
               if(_loc6_ != null)
               {
                  this.addChild(_loc6_);
                  _loc6_.gotoAndStop(_loc2_);
                  TipsManager.getInstance().addComplexTips(_loc6_,StatusUtil.getTips(this.statuses[_loc5_]),StatusUtil.getDetailTips(this.statuses[_loc5_]),0,9,9,TipsType.NORMAL,true,180);
               }
            }
            _loc5_++;
         }
      }
      
      public function clearStatus() : void
      {
         var _loc2_:MovieClip = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.STATE_LEN)
         {
            _loc2_ = this.icons[_loc1_] as MovieClip;
            if(_loc2_ != null)
            {
               _loc2_.gotoAndStop(1);
               if(_loc2_.parent)
               {
                  _loc2_.parent.removeChild(_loc2_);
                  TipsManager.getInstance().removeTips(_loc2_);
               }
            }
            _loc1_++;
         }
      }
      
      private function initStateIcons() : void
      {
         var _loc2_:MovieClip = null;
         this.icons = [];
         var _loc1_:int = 0;
         while(_loc1_ < this.STATE_LEN)
         {
            _loc2_ = this.getChildByName("s" + _loc1_.toString()) as MovieClip;
            if(_loc2_ != null)
            {
               _loc2_.gotoAndStop(1);
               this.icons.push(_loc2_);
               this.removeChild(_loc2_);
            }
            _loc1_++;
         }
      }
      
      private function setView(param1:PetBriefInfo) : void
      {
         var _loc3_:String = null;
         var _loc4_:* = null;
         var _loc8_:PlayerBattleInfo = null;
         var _loc2_:String = "Lv";
         if((FightController.instance.trainingTowerType == TrainingFightTypes.DEFEND_TYPE || FightController.instance.trainingTowerType == TrainingFightTypes.STATUS_TYPE) && !FightData.instance.isMySide(this.locaId))
         {
            _loc3_ = "?";
         }
         else
         {
            _loc3_ = param1.level.toString();
         }
         if(param1.raceId == 20372 || param1.raceId == 20374)
         {
            _loc3_ = "?";
         }
         if(this.lingshouRealitySlotId == -1)
         {
            _loc4_ = param1.name;
         }
         else
         {
            _loc8_ = FightData.instance.getPlayerInfoBySlotId(this.lingshouRealitySlotId);
            _loc4_ = (_loc8_.myPets[0] as PetBriefInfo).name + "的魂";
         }
         TextField(this.txtInfo).htmlText = "<font size=\'14\'>" + _loc2_ + _loc3_ + "</font><font size=\'12\'>" + _loc4_ + "</font> ";
         TextField(this.txtInfo).mouseEnabled = false;
         var _loc5_:MovieClip = this.hp.ml;
         var _loc6_:MovieClip = this.hp.mr;
         var _loc7_:int = param1.maxHp + param1.maxShield;
         _loc5_.width = param1.curHp * 1 * this.HP_LEN / _loc7_;
         _loc6_.width = param1.currentShield * 1 * this.HP_LEN / _loc7_;
         _loc5_.x = 0;
         _loc6_.x = _loc5_.width;
         this.setStatus(param1.status);
         this.setBE(param1);
      }
      
      private function addAttribute(param1:PetBriefInfo) : void
      {
         var _loc3_:Object = null;
         var _loc4_:PlayerBattleInfo = null;
         var _loc2_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         if(this.lingshouRealitySlotId == -1)
         {
            _loc3_ = _loc2_.getPetMes(param1.raceId);
         }
         else
         {
            _loc4_ = FightData.instance.getPlayerInfoBySlotId(this.lingshouRealitySlotId);
            _loc3_ = _loc2_.getPetMes((_loc4_.myPets[0] as PetBriefInfo).raceId);
         }
         if(int(_loc3_.attribute) != int(_loc3_.attribute2))
         {
            this.setAttribute(-52,6.55,_loc3_.attribute);
            this.setAttribute(-29,6.55,_loc3_.attribute2);
         }
         else
         {
            this.setAttribute(-29,6.55,_loc3_.attribute);
         }
      }
      
      private function setAttribute(param1:Number, param2:Number, param3:int) : void
      {
         var _loc4_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         var _loc5_:Sprite = _loc4_.getSkillAttributeIcon(param3);
         _loc5_.x = param1;
         _loc5_.y = param2;
         this.addChild(_loc5_);
         DisplayUtil.scaleDisplay(_loc5_,0,20);
         var _loc6_:String = _loc4_.getPetAttributeTipsByattributeId(param3);
         TipsManager.getInstance().addTips(_loc5_,_loc6_);
      }
      
      private function setBE(param1:PetBriefInfo) : void
      {
         if(!FightController.isShowBattleEffectiveness)
         {
            if(this.spe.parent)
            {
               this.spe.parent.removeChild(this.spe);
            }
            return;
         }
         this.addChild(this.spe);
         var _loc2_:TextField = this.spe.getChildByName("txtBE") as TextField;
         _loc2_.mouseEnabled = false;
         var _loc3_:IPetBattleEffDataService = ServicePool.instance.getService(IPetBattleEffDataService);
         var _loc4_:int = int(_loc3_.getPetBattleEffectiveness(param1));
         _loc2_.text = _loc4_.toString();
      }
      
      public function refresh(param1:PetBriefInfo) : void
      {
         this.setView(param1);
      }
   }
}

