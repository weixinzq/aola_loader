package mmo.petpackage.controller.helper
{
   import flash.display.MovieClip;
   import mmo.common.AlignType;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.gq.newskill.GQNewSkillConfig;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.loader.scheduler.SubDomain;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.play.actthings.data.ActClientSender;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.pet.ActPetDataUpdateHelper;
   
   public class PetPackageGQNewSkillHelper
   {
      
      private static const _instance:PetPackageGQNewSkillHelper = new PetPackageGQNewSkillHelper();
      
      private var _petDataService:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
      
      public function PetPackageGQNewSkillHelper()
      {
         super();
      }
      
      public static function getInstance() : PetPackageGQNewSkillHelper
      {
         return PetPackageGQNewSkillHelper._instance;
      }
      
      public function getSelectPbi() : PetBriefInfo
      {
         var _loc1_:int = int(this._petDataService.getSelectPetId());
         return this._petDataService.getPetByPetId(_loc1_);
      }
      
      public function isShowingGQNewSkill() : Boolean
      {
         var _loc1_:PetBriefInfo = this.getSelectPbi();
         if(_loc1_ == null)
         {
            return false;
         }
         return _loc1_.usingGQSkillType == 1;
      }
      
      public function changeGQNewSkillState() : void
      {
         var isShowingGQNewSkill:Boolean;
         var value:int;
         var isChange2NewSkill:Boolean;
         var param:Object;
         var pmId:int = 0;
         var self:PetPackageGQNewSkillHelper = this;
         if(GQNewSkillConfig.isPetHaveOnlyNewSkill(this.getSelectPbi().raceId))
         {
            return;
         }
         isShowingGQNewSkill = this.isShowingGQNewSkill();
         value = isShowingGQNewSkill ? 0 : 1;
         isChange2NewSkill = !isShowingGQNewSkill;
         pmId = int(this.getSelectPbi().id);
         param = {
            "skillType":value,
            "petId":pmId
         };
         ActClientSender.sendMessage("PocketMonsterExtension","1218",param,function(param1:Object):void
         {
            ActPetDataUpdateHelper.getInstance().addUpdateCallback(this.afterAddUpdate,null,this);
            PetDetailDataMap.instance.tryUpdateCachhe(pmId,true);
         });
      }
      
      private function afterAddUpdate() : void
      {
         ActPetDataUpdateHelper.getInstance().removeUpdateCallback(this.afterAddUpdate);
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("GQPetChangeUseSkillType",{}));
      }
      
      private function playChangeUseSkillMv(param1:Boolean, param2:Function = null, param3:String = "", param4:Boolean = true) : void
      {
         var cls:String = null;
         var isChange2NewSkill:Boolean = param1;
         var callback:Function = param2;
         var localKey:String = param3;
         var isMovie:Boolean = param4;
         var onGetViewRes:Function = function():void
         {
            var mv:MovieClip = null;
            var CLZ:Class = getResDomain().applicationDomain.getDefinition(cls) as Class;
            mv = new CLZ();
            ActComHelper.setVisible(mv,"mcHunKa_0",!isChange2NewSkill);
            ActComHelper.setVisible(mv,"mcHunKa_1",isChange2NewSkill);
            mv.addFrameScript(mv.totalFrames - 1,function():void
            {
               ModalDialogManager.getInstance().removeModalDialog(mv);
            });
            mv.gotoAndPlay(1);
            ModalDialogManager.getInstance().addModalDialog(mv,AlignType.NONE,PanelEffect.NONE,false);
         };
         var getResDomain:Function = function():ResDomain
         {
            return SubDomain.getInstance().getDomain(SubDomain.ITEM_DOMAIN);
         };
         var url:String = "pet/guangqichangeuseskillmv";
         cls = "mmo.pet.GQChangeUseSkillMv";
         var resParams:ResParams = ResParams.create(url,onGetViewRes,getResDomain(),ResPriority.NORMAL,[cls],null);
         ResScheduler.getRes(resParams);
      }
   }
}

