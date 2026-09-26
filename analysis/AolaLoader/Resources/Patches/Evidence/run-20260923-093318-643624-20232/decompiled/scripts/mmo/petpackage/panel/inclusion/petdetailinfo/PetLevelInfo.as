package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.tips.NotifyQueue;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.callback.FunCallInfo;
   import mmo.interfaces.commonpanel.ConfirmPanelParam;
   import mmo.interfaces.commonpanel.ICommonPanelService;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.interfaces.pet.data.petbattleeff.PetBattleDetectHelper;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.secondpwd.ISecondPwdService;
   import mmo.petpackage.controller.helper.AddPetDetailInfoHelper;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.commonpanel.item.MaterialObj;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2604")]
   public class PetLevelInfo extends PetDetailBase
   {
      
      public var btnFullLevel:SimpleButton;
      
      public var btn_shareexp:SimpleButton;
      
      public var btnhowlevel:SimpleButton;
      
      public var mcEffProg:MovieClip;
      
      public var mcl0:MovieClip;
      
      public var mcl1:MovieClip;
      
      public var mcl2:MovieClip;
      
      public var txtEff:TextField;
      
      private var _btnFullLevel:SimpleButton;
      
      private var _petDataService:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
      
      public function PetLevelInfo()
      {
         super();
      }
      
      override protected function initUI() : void
      {
         this._btnFullLevel = this.getChildByName("btnFullLevel") as SimpleButton;
         this._btnFullLevel.addEventListener(MouseEvent.CLICK,this.onClickFullLevel);
         PetClient.instance.getShareExp();
         AddPetDetailInfoHelper.addDetailInfoMC(0,this,this.setCanUpdate);
         this._petDataService.addEventListener(PetDataServiceEvent.RSPN_PM_GAIN_EXP,this.onRspn_pm_gain_exp);
         this._petDataService.addEventListener(PetDataServiceEvent.RSPN_PM_LEVELUP,this.onRspn_pm_gain_exp);
      }
      
      override public function dispose() : void
      {
         if(this._btnFullLevel)
         {
            this._btnFullLevel.removeEventListener(MouseEvent.CLICK,this.onClickFullLevel);
            this._btnFullLevel = null;
         }
         this._petDataService.removeEventListener(PetDataServiceEvent.RSPN_PM_GAIN_EXP,this.onRspn_pm_gain_exp);
         this._petDataService.removeEventListener(PetDataServiceEvent.RSPN_PM_LEVELUP,this.onRspn_pm_gain_exp);
         super.dispose();
      }
      
      private function onClickFullLevel(param1:MouseEvent) : void
      {
         var content:String;
         var self:PetLevelInfo = null;
         var needExp:int = 0;
         var param:ConfirmPanelParam = null;
         var sureFullLevel:Function = null;
         var afterVertify:Function = null;
         var onGainExp:Function = null;
         var evt:MouseEvent = param1;
         sureFullLevel = function():void
         {
            if(needExp > self._petDataService.getMyInfo().pmExp)
            {
               NotifyQueue.getInstance().add("已经超过你积累的经验了!");
               return;
            }
            var _loc1_:FunCallInfo = new FunCallInfo(afterVertify);
            var _loc2_:ISecondPwdService = ServiceContainer.getService(ISecondPwdService) as ISecondPwdService;
            _loc2_.verify(_loc1_);
         };
         afterVertify = function():void
         {
            SocketClient.instance.addEventListener(PetClient.RSPN_PM_GAIN_EXP,onGainExp);
            PetClient.instance.gainExp(self.pdi.id,needExp,true);
         };
         onGainExp = function(param1:SocketClientEvent):void
         {
            SocketClient.instance.removeEventListener(PetClient.RSPN_PM_GAIN_EXP,onGainExp);
            PetClient.instance.getShareExp();
         };
         self = this;
         if(self.pdi.level == 100)
         {
            NotifyQueue.getInstance().add("你的亚比已经100级，不能再分配经验了！");
            return;
         }
         needExp = this.getNeedExp();
         content = "是否消耗" + needExp + "经验分配给" + this.pdi.name + "吗？";
         param = new ConfirmPanelParam();
         param.content = content;
         param.title = "经验分配";
         param.onSure = sureFullLevel;
         param.todayLocalKey = "PetPackage_FullLevel";
         param.itemArray = [new MaterialObj(MaterialTypes.ITEM,1000001,needExp)];
         ServiceContainer.tryGetService(ICommonPanelService,function(param1:ICommonPanelService, param2:Object):void
         {
            ProgressFullSprite.close();
            param1.showConfirmPanel(param);
         });
      }
      
      override protected function refreshUI() : void
      {
         this.refreshLevelUI();
      }
      
      private function refreshLevelUI() : void
      {
         var _loc1_:int = int(PetBattleDetectHelper.getDetectNumByType(0,pdi));
         var _loc2_:int = int(PetBattleDetectHelper.getMaxNum(pdi,0));
         ActComHelper.setMcProg(ActComHelper.getChildNode(this,"mcEffProg") as MovieClip,[0,_loc2_],[0,100],_loc1_);
         ActComHelper.setTxtValue(this,"txtEff",Math.floor(_loc1_ * 100 / _loc2_) + "%");
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 1;
         if(pdi != null)
         {
            _loc3_ = int(pdi.level);
            _loc4_ = int(pdi.curLvExp);
            _loc5_ = pdi.curLvExp + pdi.toNextLevel;
         }
         this.btn_shareexp.visible = pdi != null;
         this._btnFullLevel.visible = pdi != null;
         TipsManager.getInstance().replaceTips(this._btnFullLevel,"可快捷消耗经验提升当前亚比等级至100级！");
         var _loc6_:Array = Panel_Helper.getSubClips(this,3,"mcl");
         ArtNumberManager.setNumber(_loc6_,_loc3_);
         var _loc7_:String = _loc4_ + "/" + _loc5_;
         Panel_Helper.setTextValue(this,"txt_exp",_loc7_);
      }
      
      private function getNeedExp() : int
      {
         var _loc1_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc2_:int = int(_loc1_.getOperationPM(this.pdi.raceId).pmData.pmExpType);
         var _loc3_:int = 100;
         var _loc4_:int = int(_loc1_.customData.pmExpMap.getPMLevelExp(_loc2_,_loc3_));
         var _loc5_:int = int(_loc1_.customData.pmExpMap.getPMLevelExp(_loc2_,this.pdi.level));
         return _loc4_ - pdi.curLvExp - _loc5_;
      }
      
      private function onRspn_pm_gain_exp(param1:PetDataServiceEvent) : void
      {
         this.refreshUI();
      }
   }
}

