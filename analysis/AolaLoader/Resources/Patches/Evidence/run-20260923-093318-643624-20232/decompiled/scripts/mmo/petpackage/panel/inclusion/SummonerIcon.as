package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.interfaces.summoner.ISummonerDataService;
   import mmo.interfaces.summoner.skill.SummonerSkillInfo;
   import mmo.play.activity.activitylimiter.ActivityId;
   import mmo.play.activity.activitylimiter.ActivityLimiter;
   import mmo.play.activity.helper.SummonerPanelHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2561")]
   public class SummonerIcon extends MovieClip
   {
      
      private var _petDataService:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
      
      private var _summonerDataService:ISummonerDataService = ServiceContainer.getService(ISummonerDataService) as ISummonerDataService;
      
      public function SummonerIcon()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         CommonEventDispatcher.instance.addEventListener("on_close_summoner_info_panel",this.onSummonerInfoPanelClose);
         this._petDataService.addEventListener(PetDataServiceEvent.ON_HIGHTES_BATTLE_EFF_UPDATE,this.onHighestBEUpdated);
         this.addEventListener(MouseEvent.CLICK,this.onClickIcon);
         this.refreshIconView();
      }
      
      private function onSummonerInfoPanelClose(param1:Event) : void
      {
         this.refreshIconView();
      }
      
      private function onClickIcon(param1:MouseEvent) : void
      {
         if(!this.mouseChildren)
         {
            return;
         }
         this.showSummonerPanel();
      }
      
      private function showSummonerPanel() : void
      {
         SummonerPanelHelper.showSummonerInfoPanel();
      }
      
      private function onHighestBEUpdated(param1:PetDataServiceEvent) : void
      {
         this.refreshIconView();
      }
      
      private function refreshIconView() : void
      {
         var _loc4_:String = null;
         var _loc5_:String = null;
         var _loc1_:Boolean = Boolean(ActivityLimiter.checkIsOpen(ActivityId.SUMMONER));
         var _loc2_:int = int(ActivityLimiter.getActivityOpenBe(ActivityId.SUMMONER));
         if(!_loc1_)
         {
            this.mouseChildren = false;
            this.buttonMode = false;
            DisplayUtil.applyGray(this);
            TipsManager.getInstance().replaceTips(this,"战斗力到达" + _loc2_ + "才推荐开启这个功能哦！");
            this.gotoAndStop(1);
            return;
         }
         this.mouseChildren = true;
         this.buttonMode = true;
         DisplayUtil.clearGray(this);
         var _loc3_:SummonerSkillInfo = this._summonerDataService.getMySummonerData().curEquipedSkills[0];
         if(_loc3_)
         {
            _loc4_ = _loc3_.skillName + "Lv." + _loc3_.level;
            _loc5_ = _loc3_.skillDesc;
            this.gotoAndStop(_loc3_.skillId + 2);
            TipsManager.getInstance().replaceComplexTips(this,_loc4_,_loc5_,0,-100,-100);
         }
         else
         {
            this.gotoAndStop(1);
            TipsManager.getInstance().replaceTips(this,"暂未装备召唤师技能！");
         }
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener("on_close_summoner_info_panel",this.onSummonerInfoPanelClose);
         this._petDataService.removeEventListener(PetDataServiceEvent.ON_HIGHTES_BATTLE_EFF_UPDATE,this.onHighestBEUpdated);
      }
   }
}

