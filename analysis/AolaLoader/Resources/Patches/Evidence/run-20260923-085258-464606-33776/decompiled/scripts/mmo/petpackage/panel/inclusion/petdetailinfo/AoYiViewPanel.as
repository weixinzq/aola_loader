package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.callback.FunCallInfo;
   import mmo.interfaces.pet.data.AoYiConfig;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.layer.LayerManager;
   import mmo.play.activity.helper.SceneLoad_Helper;
   import mmo.play.scene.SceneManager;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2395")]
   public class AoYiViewPanel extends PetDetailBase
   {
      
      public var btnGoLearn:SimpleButton;
      
      public var mcType:MovieClip;
      
      public var txtSkillDes:TextField;
      
      public var txtSkillName:TextField;
      
      public function AoYiViewPanel()
      {
         super();
         addFrameScript(0,this.frame1);
         this.canUpdateUI = true;
         this.gotoAndStop(1);
         this.addEventListener(MouseEvent.CLICK,this.clickBtn);
      }
      
      private function clickBtn(param1:MouseEvent) : void
      {
         if(param1.target.name == "btnGoLearn")
         {
            ModalDialogManager.getInstance().clearAll();
            SceneLoad_Helper.loadScene("superseries1","btnAoYiMachine_150710",new FunCallInfo(this.onLoadScene));
         }
      }
      
      private function onLoadScene() : void
      {
         if(SceneManager.getInstance().loadedSceneInfo.sceneName == "superseries1")
         {
            LayerManager.getBaseControl().visible = true;
         }
      }
      
      override protected function refreshUI() : void
      {
         if(!AoYiConfig.isAoYiPet(this.pdi.raceId))
         {
            return;
         }
         this.gotoAndStop(this.pdi.isGetAoYiSkill ? 1 : 2);
         var _loc1_:int = int(AoYiConfig.getAoYiSkillId(this.pdi.raceId));
         var _loc2_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc3_:PMSkill = _loc2_.customData.pmSkillMap.getSkill(_loc1_);
         var _loc4_:TextField = this.getChildByName("txtSkillName") as TextField;
         _loc4_.mouseEnabled = false;
         _loc4_.text = _loc3_.newCnName;
         var _loc5_:MovieClip = this.getChildByName("mcType") as MovieClip;
         _loc5_.gotoAndStop(AoYiConfig.getAoYiSkillType(_loc1_) + 1);
         var _loc6_:TextField = this.getChildByName("txtSkillDes") as TextField;
         if(_loc6_ != null)
         {
            _loc6_.mouseEnabled = false;
            _loc6_.text = _loc3_.clientDesc;
         }
      }
      
      internal function frame1() : *
      {
         stop();
      }
   }
}

