package mmo.petfightnew.common.panel.skill.big
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.panel.DegeneratorYulingBigKillPanel;
   import mmo.petfightnew.common.util.DegeneratorPetHelper;
   
   public class BigSkillMCHandler_Degenerator extends BigSkillMCHandler
   {
      
      private var _yulingBigKillPanel:DegeneratorYulingBigKillPanel = null;
      
      public function BigSkillMCHandler_Degenerator()
      {
         super();
      }
      
      override public function update() : void
      {
         var _loc5_:MovieClip = null;
         var _loc6_:MovieClip = null;
         var _loc9_:String = null;
         super.update();
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         if(this._pmService.getOperationPM(_loc1_.raceId) == null || this._pmService.getOperationPM(_loc1_.raceId).pmData == null)
         {
            throw new Error("PM数据有问题，应该是没有" + _loc1_.raceId + "的" + _loc1_.name + "这只亚比！");
         }
         var _loc2_:int = int(this._pmService.getOperationPM(_loc1_.raceId).pmData.maxDegeneratorSoulNum);
         var _loc3_:int = int(_loc1_.curDegeneratorSoulNum);
         var _loc4_:PMSkill = DegeneratorPetHelper.getDegeneratorPetBigSkill(_loc1_);
         var _loc7_:* = _loc4_.clientDesc;
         if(_loc4_.getSkillType() == PMSkillTypes.DEGENERATOR_SHEN_KILL_BIG)
         {
            this._mcChangeView.gotoAndStop(13);
            setMouseChildren(true);
            _loc5_ = this._mcChangeView.getChildByName("mcbig") as MovieClip;
            _loc5_.gotoAndStop(_loc2_ - 4);
            _loc5_.mcname.mouseChildren = _loc5_.mcname.mouseEnabled = false;
            _loc6_ = _loc5_.mc.mcsouls;
            _loc6_.mouseChildren = _loc6_.mouseEnabled = false;
            _loc6_.gotoAndStop(_loc6_.totalFrames);
            (this._mcChangeView.getChildByName("mcturncount") as MovieClip).gotoAndStop(_loc1_.changeViewRound + _loc1_.persistRound - FightController.instance.turnCount);
         }
         else
         {
            if(_loc4_.getSkillType() == PMSkillTypes.DEGENERATOR_YU_KILL_BIG)
            {
               this._mcChangeView.gotoAndStop(14);
               setMouseChildren(true);
            }
            else if(_loc4_.getSkillType() == PMSkillTypes.DEGENERATOR_SHENQI_KILL_BIG)
            {
               this._mcChangeView.gotoAndStop(15);
               setMouseChildren(true);
            }
            else
            {
               this._mcChangeView.gotoAndStop(12);
               setMouseChildren(_loc3_ >= _loc4_.costSoulNum);
            }
            _loc5_ = this._mcChangeView.getChildByName("mcbig") as MovieClip;
            _loc5_.gotoAndStop(_loc2_ - 4);
            _loc5_.mcname.mouseChildren = _loc5_.mcname.mouseEnabled = false;
            _loc6_ = _loc5_.mc.mcsouls;
            _loc6_.mouseChildren = _loc6_.mouseEnabled = false;
            _loc6_.gotoAndStop(_loc3_ + 1);
            _loc7_ += "\n-------\n当前拥有" + _loc3_ + "异次元元气。";
            if(_loc3_ < _loc4_.costSoulNum)
            {
               _loc7_ += "\n-------\n异次元元气不足，不能使用异次元必杀！";
            }
         }
         var _loc8_:Sprite = this._mcChangeView.curClip as Sprite;
         if(_loc4_.getSkillType() != PMSkillTypes.DEGENERATOR_YU_KILL_BIG)
         {
            _loc9_ = _loc4_.newCnName + " 威力：" + this.getSkillPowerDesc(_loc4_.power);
            TipsManager.getInstance().replaceComplexTips(_loc8_,_loc9_,_loc7_,100,-100,9);
         }
         else
         {
            TipsManager.getInstance().removeTips(_loc8_);
         }
      }
      
      override public function onMouseRollOver(param1:MouseEvent) : void
      {
         var _loc2_:PetBriefInfo = getOperatingPetInfo();
         var _loc3_:Boolean = Boolean(this._pmService.getOperationPM(_loc2_.raceId).pmData.isDegeneratorPM());
         var _loc4_:PMSkill = DegeneratorPetHelper.getDegeneratorPetBigSkill(_loc2_);
         if(_loc3_ && _loc4_.getSkillType() == PMSkillTypes.DEGENERATOR_YU_KILL_BIG)
         {
            if(this._yulingBigKillPanel == null)
            {
               this._yulingBigKillPanel = new DegeneratorYulingBigKillPanel();
               this._yulingBigKillPanel.x = -197;
               this._yulingBigKillPanel.y = -29;
            }
            this._mcChangeView.addChild(this._yulingBigKillPanel);
         }
      }
      
      override public function onMouseRollOut() : void
      {
         if(this._yulingBigKillPanel != null)
         {
            DisplayUtil.stopAndRemove(this._yulingBigKillPanel);
            this._yulingBigKillPanel = null;
         }
      }
      
      override public function onClicked(param1:MouseEvent) : void
      {
         var _loc2_:PetBriefInfo = this.getOperatingPetInfo();
         var _loc3_:int = int(_loc2_.curDegeneratorSoulNum);
         var _loc4_:PMSkill = DegeneratorPetHelper.getDegeneratorPetBigSkill(_loc2_);
         if((Boolean(_loc4_)) && _loc3_ >= _loc4_.costSoulNum)
         {
            UseBigSkillHandler.instance.handleUse(_loc2_,_loc4_.skillId,_loc4_.getSkillType());
         }
      }
      
      override public function dispose() : void
      {
         super.dispose();
         DisplayUtil.stop(this._yulingBigKillPanel);
         this._yulingBigKillPanel = null;
      }
      
      override protected function care() : Boolean
      {
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         return this._pmService.getOperationPM(_loc1_.raceId).pmData.isDegeneratorPM();
      }
   }
}

