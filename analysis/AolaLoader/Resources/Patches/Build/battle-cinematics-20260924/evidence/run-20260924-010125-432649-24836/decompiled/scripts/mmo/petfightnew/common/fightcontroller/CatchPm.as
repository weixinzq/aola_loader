package mmo.petfightnew.common.fightcontroller
{
   import com.greensock.TweenMax;
   import com.greensock.data.TweenLiteVars;
   import flash.display.MovieClip;
   import flash.geom.Point;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightItemData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.manager.FightMovieManager;
   import mmo.petfightnew.common.manager.FightTweenMaxManager;
   import mmo.petfightnew.common.panel.CatchDonePanel;
   import mmo.petfightnew.common.util.PositionUtil;
   
   public class CatchPm implements IDispose
   {
      
      private static var _instance:CatchPm;
      
      private var fightPanel:FightPanel;
      
      public var isCatchLevelUp:Boolean = false;
      
      public var selectedCatchItemId:int;
      
      public var isCatched:Boolean = false;
      
      public function CatchPm()
      {
         super();
      }
      
      public static function get instance() : CatchPm
      {
         if(_instance == null)
         {
            _instance = new CatchPm();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
      }
      
      public function catchPm(param1:Object) : void
      {
         var _loc2_:int = int(param1.tarSId);
         var _loc3_:int = int(FightData.instance.playerInfo[_loc2_].locaId);
         if(param1.pmId != 0)
         {
            if(param1.lv > FightData.instance.myInfo.pmCatchLevel)
            {
               this.isCatchLevelUp = true;
            }
            PetClient.instance.viewAllPM();
            this.showCatchDone(param1);
            this.isCatched = true;
         }
         else
         {
            this.showCatchFail(_loc3_,param1);
         }
         FightItemData.instance.useCatchItem(this.selectedCatchItemId,1);
      }
      
      public function getShowCatchableIconDatas() : Array
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc1_:Array = [];
         if(!FightController.instance.canCatch)
         {
            return _loc1_;
         }
         for each(_loc2_ in FightData.instance.playerInfo)
         {
            _loc3_ = int(_loc2_.locaId);
            if(!(FightData.instance.isMySide(_loc3_) || _loc2_.myPets[0].curHp <= 0))
            {
               _loc4_ = int(_loc2_.myPets[0].curHp);
               _loc5_ = int(_loc2_.myPets[0].maxHp);
               if(_loc4_ < _loc5_ * 0.2)
               {
                  _loc1_.push(_loc3_);
               }
            }
         }
         return _loc1_;
      }
      
      private function showCatchDone(param1:Object) : void
      {
         var position:Point;
         var locaId:int = 0;
         var mc:MovieClip = null;
         var params:Object = param1;
         var slotId:int = int(params.tarSId);
         locaId = int(FightData.instance.playerInfo[slotId].locaId);
         this.fightPanel.hideAllCanCatchMovie();
         mc = new McCatchDone();
         position = PositionUtil.getDefaultPosition(locaId);
         mc.x = position.x;
         mc.y = position.y;
         this.fightPanel.addChild(mc);
         FightMovieManager.instance.addMovie(mc);
         mc.addFrameScript(24,function():*
         {
            var tweenMax:TweenMax = null;
            var myTweenLiteVars:TweenLiteVars = new TweenLiteVars();
            tweenMax = null;
            myTweenLiteVars.prop("y",mc.y - 10);
            myTweenLiteVars.prop("alpha",0);
            myTweenLiteVars.useFrames(true);
            myTweenLiteVars.onComplete(function():void
            {
               FightTweenMaxManager.instance.removeTweenMax(tweenMax);
            });
            tweenMax = new TweenMax(fightPanel.petMCList[locaId],10,myTweenLiteVars);
            FightTweenMaxManager.instance.addTweenMax(tweenMax);
         },mc.totalFrames - 1,function():*
         {
            FightMovieManager.instance.removeMovie(mc);
            DisplayUtil.stopAndRemove(mc);
            DisplayUtil.stopAndRemove(fightPanel.petMCList[locaId]);
            fightPanel.hidePetInfoMC(locaId);
            if(params.reqId == SocketClient.instance.myUserId)
            {
               ModalDialogManager.getInstance().addModalDialog(new CatchDonePanel(params));
               fightPanel.setFightClicked();
            }
            else
            {
               FightController.instance.startHandle();
            }
         });
         mc.gotoAndPlay(1);
         FightController.instance.playSound("x7006");
      }
      
      private function showCatchMc(param1:Object) : void
      {
         var params:Object = param1;
         var location:int = int(params.lc);
         var locName:String = location == 1 ? "mmo.petfight.McCatchPackage" : "mmo.petfight.McCatchHouse";
         ProgressFullSprite.show();
         ResScheduler.getResource("petfightres/catchres",function(param1:MovieClip):*
         {
            var mc:MovieClip = param1;
            dispose();
            ProgressFullSprite.close();
            ModalDialogManager.getInstance().addModalDialog(mc,AlignType.NONE,PanelEffect.NONE,false);
            mc.mc.addFrameScript(mc.mc.totalFrames - 1,function():*
            {
               ModalDialogManager.getInstance().removeModalDialog(mc);
            });
            mc.mc.gotoAndPlay(1);
         },locName,null,null,ResPriority.NORMAL,true,FightData.instance.applicationDomain);
      }
      
      private function showCatchFail(param1:int, param2:Object) : void
      {
         var position:Point;
         var mc:MovieClip = null;
         var myTweenLiteVars:TweenLiteVars = null;
         var myTweenMax:TweenMax = null;
         var locaId:int = param1;
         var params:Object = param2;
         this.fightPanel.hideAllCanCatchMovie();
         position = PositionUtil.getDefaultPosition(locaId);
         mc = new McCatchFail();
         mc.x = position.x;
         mc.y = position.y;
         this.fightPanel.addChild(mc);
         myTweenMax = null;
         FightMovieManager.instance.addMovie(mc);
         mc.addFrameScript(15,function():*
         {
            myTweenLiteVars = new TweenLiteVars();
            myTweenLiteVars.prop("y",mc.y - 10);
            myTweenLiteVars.prop("alpha",0);
            myTweenLiteVars.useFrames(true);
            myTweenLiteVars.onComplete(function():void
            {
               FightTweenMaxManager.instance.removeTweenMax(myTweenMax);
            });
            myTweenMax = new TweenMax(fightPanel.petMCList[locaId],10,myTweenLiteVars);
            FightTweenMaxManager.instance.addTweenMax(myTweenMax);
         },51,function():*
         {
            myTweenLiteVars = new TweenLiteVars();
            myTweenLiteVars.prop("y",mc.y);
            myTweenLiteVars.prop("scaleX",1);
            myTweenLiteVars.prop("scaleY",1);
            myTweenLiteVars.prop("alpha",1);
            myTweenLiteVars.useFrames(true);
            myTweenLiteVars.onComplete(function():void
            {
               FightTweenMaxManager.instance.removeTweenMax(myTweenMax);
            });
            myTweenMax = new TweenMax(fightPanel.petMCList[locaId],10,myTweenLiteVars);
            FightTweenMaxManager.instance.addTweenMax(myTweenMax);
            FightController.instance.playSound("x7007");
         },mc.totalFrames - 1,function():*
         {
            if(params.reqId == SocketClient.instance.myUserId)
            {
               fightPanel.setFightClicked();
            }
            onCatchFailEnd(mc);
         });
         mc.gotoAndPlay(1);
      }
      
      private function onCatchFailEnd(param1:MovieClip) : void
      {
         FightMovieManager.instance.removeMovie(param1);
         DisplayUtil.stopAndRemove(param1);
         FightController.instance.startHandle();
      }
      
      public function dispose() : void
      {
         this.fightPanel = null;
         _instance = null;
      }
   }
}

