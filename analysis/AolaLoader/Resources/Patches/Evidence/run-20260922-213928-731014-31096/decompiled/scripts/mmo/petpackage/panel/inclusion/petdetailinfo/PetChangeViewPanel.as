package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetChangeViewConfig;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.FaceDirectionTypes;
   import mmo.play.scene.SceneExtInfo;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2478")]
   public class PetChangeViewPanel extends PetDetailBase
   {
      
      public var mcCurEffect0:MovieClip;
      
      public var mcCurEffect1:MovieClip;
      
      public var mcCurEffect2:MovieClip;
      
      public var mcCurEffect3:MovieClip;
      
      public var mcIcon:MovieClip;
      
      public var mcNextEffect0:MovieClip;
      
      public var mcNextEffect1:MovieClip;
      
      public var mcNextEffect2:MovieClip;
      
      public var mcNextEffect3:MovieClip;
      
      public var mcProgress:MovieClip;
      
      public var spIcon0:MovieClip;
      
      public var spIcon1:MovieClip;
      
      public var spIcon2:MovieClip;
      
      public var spIcon3:MovieClip;
      
      public var spIcon4:MovieClip;
      
      public var spIcon5:MovieClip;
      
      public var spIcon6:MovieClip;
      
      public var spIcon7:MovieClip;
      
      public var txtCurRound:TextField;
      
      public var txtEnergy:TextField;
      
      public var txtNextRound:TextField;
      
      public function PetChangeViewPanel()
      {
         super();
         addFrameScript(0,this.frame1);
         this.canUpdateUI = true;
         this.addEventListener(MouseEvent.CLICK,this.clickBtn);
      }
      
      private function clickBtn(param1:MouseEvent) : void
      {
         var _loc2_:SceneExtInfo = null;
         if(param1.target.name == "btnGoUpdate")
         {
            ModalDialogManager.getInstance().clearAll();
            SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED,this.onLoadScene);
            _loc2_ = new SceneExtInfo();
            _loc2_.arrowInfos = ["jjjjy_0718_jiujistudy"];
            SceneManager.getInstance().loadScene("jiujistudy","default",false,false,FaceDirectionTypes.FACELEFTDOWN,_loc2_);
         }
      }
      
      private function onLoadScene(param1:SceneManagerEvent) : void
      {
         SceneManager.getInstance().removeEventListener(SceneManagerEvent.SCENE_INITED,this.onLoadScene);
         if(SceneManager.getInstance().loadedSceneInfo.sceneName == "jiujistudy")
         {
            LayerManager.getBaseControl().visible = true;
         }
      }
      
      override protected function refreshUI() : void
      {
         if(!PetChangeViewConfig.isChangeViewPet(pdi.raceId))
         {
            return;
         }
         if(PetChangeViewConfig.canUpdate(pdi.raceId,pdi.changeViewLevel))
         {
            this.gotoAndStop(1);
            this.refreshEffect(pdi);
            this.refreshLevelIcon(pdi);
            this.refreshStoneIcon(pdi);
            this.refreshEnergy(pdi);
         }
         else
         {
            this.gotoAndStop(2);
            this.refreshEffect(pdi);
            this.refreshLevelIcon(pdi);
         }
      }
      
      private function refreshEffect(param1:PetBriefInfo) : void
      {
         var _loc9_:MovieClip = null;
         var _loc10_:TextField = null;
         var _loc11_:MovieClip = null;
         var _loc12_:TextField = null;
         var _loc2_:Array = PetChangeViewConfig.getEffct(param1.raceId,param1.changeViewLevel);
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length)
         {
            _loc9_ = this.getChildByName("mcCurEffect" + _loc4_.toString()) as MovieClip;
            if(_loc9_ != null)
            {
               _loc9_.gotoAndStop(1);
               _loc9_.visible = false;
            }
            if(_loc2_[_loc4_] != 0)
            {
               if(_loc9_ == null)
               {
                  break;
               }
               _loc9_ = this.getChildByName("mcCurEffect" + _loc3_.toString()) as MovieClip;
               _loc9_.visible = true;
               _loc9_.gotoAndStop(_loc4_ + 1);
               _loc10_ = _loc9_.getChildByName("txtEffect") as TextField;
               _loc10_.mouseEnabled = false;
               _loc10_.text = "+" + int(_loc2_[_loc4_]).toString();
               _loc3_++;
            }
            _loc4_++;
         }
         var _loc5_:TextField = this.getChildByName("txtCurRound") as TextField;
         _loc5_.mouseEnabled = false;
         _loc5_.text = "变身状态持续" + PetChangeViewConfig.getRound(param1.raceId,param1.changeViewLevel).toString() + "回合";
         if(!PetChangeViewConfig.canUpdate(param1.raceId,param1.changeViewLevel))
         {
            return;
         }
         var _loc6_:Array = PetChangeViewConfig.getEffct(param1.raceId,param1.changeViewLevel + 1);
         _loc3_ = 0;
         var _loc7_:int = 0;
         while(_loc7_ < _loc6_.length)
         {
            _loc11_ = this.getChildByName("mcNextEffect" + _loc7_.toString()) as MovieClip;
            if(_loc11_ != null)
            {
               _loc11_.gotoAndStop(1);
               _loc11_.visible = false;
            }
            if(_loc6_[_loc7_] != 0)
            {
               _loc11_ = this.getChildByName("mcNextEffect" + _loc3_.toString()) as MovieClip;
               _loc11_.visible = true;
               _loc11_.gotoAndStop(_loc7_ + 1);
               _loc12_ = _loc11_.getChildByName("txtEffect") as TextField;
               _loc12_.mouseEnabled = false;
               _loc12_.text = "+" + int(_loc6_[_loc7_]).toString();
               _loc3_++;
            }
            _loc7_++;
         }
         var _loc8_:TextField = this.getChildByName("txtNextRound") as TextField;
         _loc8_.mouseEnabled = false;
         _loc8_.text = "变身状态持续" + PetChangeViewConfig.getRound(param1.raceId,param1.changeViewLevel + 1).toString() + "回合";
      }
      
      private function refreshLevelIcon(param1:PetBriefInfo) : void
      {
         var _loc2_:MovieClip = this.getChildByName("mcIcon") as MovieClip;
         _loc2_.gotoAndStop(param1.changeViewLevel + 1);
         TipsManager.getInstance().removeTips(_loc2_);
         TipsManager.getInstance().addTips(_loc2_,PetChangeViewConfig.getLevelTips(param1.changeViewLevel));
      }
      
      private function refreshStoneIcon(param1:PetBriefInfo) : void
      {
         var _loc6_:Sprite = null;
         var _loc7_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:Array = PetChangeViewConfig.getItemArr(param1.raceId,param1.changeViewLevel);
         var _loc4_:IItemService = ServiceContainer.getService(IItemService) as IItemService;
         var _loc5_:int = 0;
         while(_loc5_ < 8)
         {
            _loc6_ = this.getChildByName("spIcon" + _loc5_.toString()) as Sprite;
            _loc6_.visible = false;
            if(_loc3_[_loc5_] != -1)
            {
               _loc6_ = this.getChildByName("spIcon" + _loc2_.toString()) as Sprite;
               _loc6_.visible = true;
               _loc7_ = int(_loc3_[_loc5_]);
               TipsManager.getInstance().removeTips(_loc6_);
               TipsManager.getInstance().addComplexTips(_loc6_,_loc4_.getItemById(_loc7_).name,_loc4_.getItemById(_loc7_).description);
               if(param1.changeViewItemArr[_loc5_] == 1)
               {
                  DisplayUtil.clearFilters(_loc6_);
               }
               else
               {
                  DisplayUtil.applyGray(_loc6_);
               }
               this.addIcon(_loc6_,_loc7_);
               _loc2_++;
            }
            _loc5_++;
         }
      }
      
      private function addIcon(param1:Sprite, param2:int) : void
      {
         var container:Sprite = param1;
         var itemId:int = param2;
         DisplayUtil.clearChildren(container);
         ResScheduler.getRes(ResParams.createTemp("item/view" + itemId.toString(),function(param1:Sprite, param2:ApplicationDomain = null):void
         {
            DisplayUtil.scaleDisplay(param1,36,36);
            container.addChild(param1);
         },"mmo.item.view" + itemId.toString()));
      }
      
      private function refreshEnergy(param1:PetBriefInfo) : void
      {
         var _loc2_:int = int(PetChangeViewConfig.getMaxEnergy(param1.raceId,param1.changeViewLevel));
         var _loc3_:MovieClip = this.getChildByName("mcProgress") as MovieClip;
         var _loc4_:int = Math.floor(param1.changeViewEnergy / _loc2_ * _loc3_.totalFrames) + 1;
         _loc3_.gotoAndStop(_loc4_);
         var _loc5_:TextField = this.getChildByName("txtEnergy") as TextField;
         _loc5_.mouseEnabled = false;
         _loc5_.text = param1.changeViewEnergy.toString() + "/" + _loc2_.toString();
      }
      
      internal function frame1() : *
      {
         stop();
      }
   }
}

