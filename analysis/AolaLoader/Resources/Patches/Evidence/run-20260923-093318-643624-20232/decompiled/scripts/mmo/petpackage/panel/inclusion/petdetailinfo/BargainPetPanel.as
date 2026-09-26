package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.pet.data.BargainPetConfig;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.loader.layer.LayerManager;
   import mmo.petpackage.controller.helper.BargainSkillIconHelper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.scene.FaceDirectionTypes;
   import mmo.play.scene.SceneExtInfo;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2503")]
   public class BargainPetPanel extends PetDetailBase
   {
      
      public var btnGoUpdate:SimpleButton;
      
      public var iconContainer:MovieClip;
      
      public var mcCurLevel:MovieClip;
      
      public var mcNextLevel:MovieClip;
      
      public var txtCurLevelDes:TextField;
      
      public var txtNextLevelDes:TextField;
      
      public var txtSkillDetail:TextField;
      
      public var txtSkillName:TextField;
      
      private var iconWidth:Number;
      
      private var iconHeight:Number;
      
      public function BargainPetPanel()
      {
         super();
         addFrameScript(0,this.frame1);
         this.canUpdateUI = true;
         var _loc1_:Sprite = this.getChildByName("iconContainer") as Sprite;
         this.iconWidth = _loc1_.width;
         this.iconHeight = _loc1_.height;
         this.addEventListener(MouseEvent.CLICK,this.clickBtn);
         this.stop();
      }
      
      private function clickBtn(param1:MouseEvent) : void
      {
         var _loc2_:SceneExtInfo = null;
         if(param1.target.name == "btnGoUpdate")
         {
            ModalDialogManager.getInstance().clearAll();
            SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED,this.onLoadScene);
            _loc2_ = new SceneExtInfo();
            _loc2_.arrowInfos = ["qsjj_20141128"];
            SceneManager.getInstance().loadScene("contractarea","default",false,false,FaceDirectionTypes.FACELEFTDOWN,_loc2_);
         }
      }
      
      private function onLoadScene(param1:SceneManagerEvent) : void
      {
         SceneManager.getInstance().removeEventListener(SceneManagerEvent.SCENE_INITED,this.onLoadScene);
         if(SceneManager.getInstance().loadedSceneInfo.sceneName == "contractarea")
         {
            LayerManager.getBaseControl().visible = true;
         }
      }
      
      override protected function refreshUI() : void
      {
         if(!BargainPetConfig.isBargainPet(pdi.raceId))
         {
            return;
         }
         if(BargainPetConfig.canUpdate(pdi.raceId,pdi.changeViewLevel))
         {
            this.gotoAndStop(1);
         }
         else
         {
            this.gotoAndStop(2);
         }
         ActComHelper.setVisible(this,"btnGoUpdate",false);
         this.refreshSkill(pdi);
         this.refreshLevel(pdi);
      }
      
      private function refreshSkill(param1:PetBriefInfo) : void
      {
         this.setText(this,"txtSkillName",BargainPetConfig.getBargainSkillName(param1.raceId));
         this.setText(this,"txtSkillDetail",BargainPetConfig.getBargainSkillDetail(param1.raceId,param1.changeViewLevel));
         var _loc2_:Sprite = this.getChildByName("iconContainer") as Sprite;
         DisplayUtil.clearChildren(_loc2_);
         BargainSkillIconHelper.loadIcon(param1.raceId,_loc2_,this.iconWidth,this.iconHeight);
      }
      
      private function setText(param1:DisplayObjectContainer, param2:String, param3:String) : void
      {
         var _loc4_:TextField = param1.getChildByName(param2) as TextField;
         if(param3 == null)
         {
            return;
         }
         _loc4_.mouseEnabled = false;
         _loc4_.text = param3;
      }
      
      private function refreshLevel(param1:PetBriefInfo) : void
      {
         var _loc3_:MovieClip = null;
         this.setText(this,"txtCurLevelDes",BargainPetConfig.getLevelEffectDes(param1.raceId,param1.changeViewLevel));
         var _loc2_:MovieClip = this.getChildByName("mcCurLevel") as MovieClip;
         _loc2_.gotoAndStop(param1.changeViewLevel + 1);
         if(this.currentFrame == 1)
         {
            this.setText(this,"txtNextLevelDes",BargainPetConfig.getLevelEffectDes(param1.raceId,param1.changeViewLevel + 1));
            _loc3_ = this.getChildByName("mcNextLevel") as MovieClip;
            _loc3_.gotoAndStop(param1.changeViewLevel + 2);
         }
      }
      
      override public function dispose() : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.clickBtn);
         super.dispose();
      }
      
      internal function frame1() : *
      {
         stop();
      }
   }
}

