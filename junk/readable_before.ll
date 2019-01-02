; ModuleID = 'opt_bamboo_before.ll'
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v32:32:32-v64:64:64-v128:128:128-n16:32:64"
target triple = "nvptx-nvidia-cl.1.0"

@llvm.used = appending global [1 x i8*] [i8* bitcast (void (i32*, i32*, i32*, i32)* @_Z8gpu_multPiS_S_i to i8*)], section "llvm.metadata"

define void @_Z8gpu_multPiS_S_i(i32* %a, i32* %b, i32* %c, i32 %N) alwaysinline {
  call void @llvm.dbg.value(metadata !{i32* %a}, i64 0, metadata !42), !dbg !43
  call void @llvm.dbg.value(metadata !{i32* %b}, i64 0, metadata !44), !dbg !43
  call void @llvm.dbg.value(metadata !{i32* %c}, i64 0, metadata !45), !dbg !43
  call void @llvm.dbg.value(metadata !{i32 %N}, i64 0, metadata !46), !dbg !47
  %1 = call i32 @llvm.nvvm.read.ptx.sreg.ctaid.y(), !dbg !48
  %2 = call i32 @llvm.nvvm.read.ptx.sreg.ntid.y(), !dbg !48
  %3 = mul i32 %1, %2, !dbg !48
  %4 = call i32 @llvm.nvvm.read.ptx.sreg.tid.y(), !dbg !48
  %5 = add i32 %3, %4, !dbg !48
  call void @llvm.dbg.value(metadata !{i32 %5}, i64 0, metadata !52), !dbg !48
  %6 = call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !53
  %7 = call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !53
  %8 = mul i32 %6, %7, !dbg !53
  %9 = call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !53
  %10 = add i32 %8, %9, !dbg !53
  call void @llvm.dbg.value(metadata !{i32 %10}, i64 0, metadata !54), !dbg !53
  %move = call i32 @llvm.nvvm.move.i32(i32 0), !dbg !55
  call void @llvm.dbg.value(metadata !{i32 %move}, i64 0, metadata !56), !dbg !55
  %11 = icmp slt i32 %10, %N, !dbg !57
  br i1 %11, label %12, label %14, !dbg !57

; <label>:12                                      ; preds = %0
  %13 = icmp slt i32 %5, %N, !dbg !57
  br label %14, !dbg !57

; <label>:14                                      ; preds = %12, %0
  %15 = phi i1 [ false, %0 ], [ %13, %12 ]
  br i1 %15, label %16, label %36, !dbg !57

; <label>:16                                      ; preds = %14
  %move1 = call i32 @llvm.nvvm.move.i32(i32 0), !dbg !59
  call void @llvm.dbg.value(metadata !{i32 %move1}, i64 0, metadata !62), !dbg !59
  br label %17, !dbg !63

; <label>:17                                      ; preds = %30, %16
  %__cuda_local_var_35624_6_non_const_sum.0 = phi i32 [ %move, %16 ], [ %29, %30 ], !dbg !63
  %i.0 = phi i32 [ %move1, %16 ], [ %31, %30 ], !dbg !63
  call void @llvm.dbg.value(metadata !{i32 %i.0}, i64 0, metadata !62)
  %18 = icmp slt i32 %i.0, %N, !dbg !63
  br i1 %18, label %19, label %32, !dbg !63

; <label>:19                                      ; preds = %17
  %20 = mul nsw i32 %5, %N, !dbg !65
  %21 = add nsw i32 %20, %i.0, !dbg !65
  %22 = getelementptr inbounds i32* %a, i32 %21, !dbg !65
  %23 = load i32* %22, align 4, !dbg !65
  %24 = mul nsw i32 %i.0, %N, !dbg !65
  %25 = add nsw i32 %24, %10, !dbg !65
  %26 = getelementptr inbounds i32* %b, i32 %25, !dbg !65
  %27 = load i32* %26, align 4, !dbg !65
  %28 = mul nsw i32 %23, %27, !dbg !65
  %29 = add nsw i32 %__cuda_local_var_35624_6_non_const_sum.0, %28, !dbg !65
  call void @llvm.dbg.value(metadata !{i32 %29}, i64 0, metadata !56), !dbg !65
  br label %30, !dbg !68

; <label>:30                                      ; preds = %19
  %31 = add nsw i32 %i.0, 1, !dbg !68
  call void @llvm.dbg.value(metadata !{i32 %31}, i64 0, metadata !62), !dbg !68
  br label %17, !dbg !68

; <label>:32                                      ; preds = %17
  %33 = mul nsw i32 %5, %N, !dbg !69
  %34 = add nsw i32 %33, %10, !dbg !69
  %35 = getelementptr inbounds i32* %c, i32 %34, !dbg !69
  store i32 %__cuda_local_var_35624_6_non_const_sum.0, i32* %35, align 4, !dbg !69
  br label %36, !dbg !69

; <label>:36                                      ; preds = %32, %14
  ret void, !dbg !70
}

declare void @llvm.dbg.declare(metadata, metadata) nounwind readnone

declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.y() nounwind readnone

declare i32 @llvm.nvvm.read.ptx.sreg.ntid.y() nounwind readnone

declare i32 @llvm.nvvm.read.ptx.sreg.tid.y() nounwind readnone

declare i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() nounwind readnone

declare i32 @llvm.nvvm.read.ptx.sreg.ntid.x() nounwind readnone

declare i32 @llvm.nvvm.read.ptx.sreg.tid.x() nounwind readnone

declare i32 @llvm.nvvm.move.i32(i32) nounwind

declare void @llvm.dbg.value(metadata, i64, metadata) nounwind readnone

declare void @abort()

!llvm.dbg.cu = !{!0}
!nvvm.annotations = !{!27, !28, !29, !28, !30, !30, !30, !30, !31, !31, !30, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !33, !33, !33, !33, !33, !33, !33, !33, !33, !33, !33, !33, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !34, !34, !34, !35, !35, !35, !34, !34, !34, !35, !35, !35, !34, !34, !34, !36, !37, !37, !28, !28, !30, !30, !36, !37, !37, !28, !28, !30, !30, !36, !37, !37, !28, !28, !30, !30, !36, !37, !37, !28, !28, !30, !30, !36, !37, !37, !28, !28, !30, !30, !38, !39, !39, !40, !40, !41, !41, !38, !39, !39, !40, !40, !41, !41, !38, !39, !39, !40, !40, !41, !41, !38, !39, !39, !40, !40, !41, !41, !38, !39, !39, !40, !40, !41, !41}
!nvvm.internalize.after.link = !{}

!0 = metadata !{i32 720913, i32 0, i32 4, metadata !"example.cu", metadata !"/home/abdul/GPU-Trident/GPU-Trident", metadata !"lgenfe: EDG 4.1", i1 true, i1 false, metadata !"", i32 0, metadata !1, metadata !3, metadata !12, metadata !1} ; [ DW_TAG_compile_unit ]
!1 = metadata !{metadata !2}
!2 = metadata !{i32 0}
!3 = metadata !{metadata !4}
!4 = metadata !{metadata !5}
!5 = metadata !{i32 720915, metadata !6, metadata !"dim3", metadata !6, i32 415, i64 96, i64 32, i32 0, i32 0, i32 0, metadata !7, i32 0, i32 0} ; [ DW_TAG_structure_type ]
!6 = metadata !{i32 720937, metadata !"/usr/local/cuda-6.0/bin/..//include/vector_types.h", metadata !"/home/abdul/GPU-Trident/GPU-Trident", null} ; [ DW_TAG_file_type ]
!7 = metadata !{metadata !8, metadata !10, metadata !11}
!8 = metadata !{i32 720909, metadata !6, metadata !"x", metadata !6, i32 417, i64 32, i64 32, i64 0, i32 0, metadata !9} ; [ DW_TAG_member ]
!9 = metadata !{i32 720932, null, metadata !"unsigned int", null, i32 0, i64 32, i64 32, i64 0, i32 0, i32 7} ; [ DW_TAG_base_type ]
!10 = metadata !{i32 720909, metadata !6, metadata !"y", metadata !6, i32 417, i64 32, i64 32, i64 32, i32 0, metadata !9} ; [ DW_TAG_member ]
!11 = metadata !{i32 720909, metadata !6, metadata !"z", metadata !6, i32 417, i64 32, i64 32, i64 64, i32 0, metadata !9} ; [ DW_TAG_member ]
!12 = metadata !{metadata !13}
!13 = metadata !{metadata !14, metadata !21, metadata !26}
!14 = metadata !{i32 720942, i32 0, metadata !15, metadata !"_Z8gpu_multPiS_S_i", metadata !"_Z8gpu_multPiS_S_i", metadata !"_Z8gpu_multPiS_S_i", metadata !15, i32 17, metadata !16, i1 false, i1 true, i32 0, i32 0, i32 0, i32 0, i1 false, void (i32*, i32*, i32*, i32)* @_Z8gpu_multPiS_S_i, null, null, metadata !1} ; [ DW_TAG_subprogram ]
!15 = metadata !{i32 720937, metadata !"example.cu", metadata !"/home/abdul/GPU-Trident/GPU-Trident", null} ; [ DW_TAG_file_type ]
!16 = metadata !{i32 720917, i32 0, metadata !"", i32 0, i32 0, i64 0, i64 0, i32 0, i32 0, i32 0, metadata !17, i32 0, i32 0} ; [ DW_TAG_subroutine_type ]
!17 = metadata !{metadata !18, metadata !19, metadata !19, metadata !19, metadata !20}
!18 = metadata !{i32 720955, null, metadata !"void", null, i32 0, i64 0, i64 0, i64 0, i32 0, i32 0} ; [ DW_TAG_unspecified_type ]
!19 = metadata !{i32 720911, null, metadata !"", null, i32 0, i64 64, i64 64, i64 0, i32 0, metadata !20, i32 0} ; [ DW_TAG_pointer_type ]
!20 = metadata !{i32 720932, null, metadata !"int", null, i32 0, i64 32, i64 32, i64 0, i32 0, i32 5} ; [ DW_TAG_base_type ]
!21 = metadata !{i32 720942, i32 0, metadata !6, metadata !"_ZN4dim3C1Ejjj", metadata !"_ZN4dim3C1Ejjj", metadata !"_ZN4dim3C1Ejjj", metadata !6, i32 419, metadata !22, i1 false, i1 true, i32 0, i32 0, i32 0, i32 0, i1 false, null, null, null, metadata !1} ; [ DW_TAG_subprogram ]
!22 = metadata !{i32 720917, i32 0, metadata !"", i32 0, i32 0, i64 0, i64 0, i32 0, i32 0, i32 0, metadata !23, i32 0, i32 0} ; [ DW_TAG_subroutine_type ]
!23 = metadata !{metadata !18, metadata !24, metadata !9, metadata !9, metadata !9}
!24 = metadata !{i32 720934, null, metadata !"", null, i32 0, i64 0, i64 0, i64 0, i32 0, metadata !25} ; [ DW_TAG_const_type ]
!25 = metadata !{i32 720911, null, metadata !"", null, i32 0, i64 64, i64 64, i64 0, i32 0, metadata !5, i32 0} ; [ DW_TAG_pointer_type ]
!26 = metadata !{i32 720942, i32 0, metadata !6, metadata !"_ZN4dim3C2Ejjj", metadata !"_ZN4dim3C2Ejjj", metadata !"_ZN4dim3C2Ejjj", metadata !6, i32 421, metadata !22, i1 false, i1 true, i32 0, i32 0, i32 0, i32 0, i1 false, null, null, null, metadata !1} ; [ DW_TAG_subprogram ]
!27 = metadata !{void (i32*, i32*, i32*, i32)* @_Z8gpu_multPiS_S_i, metadata !"kernel", i32 1}
!28 = metadata !{null, metadata !"align", i32 8}
!29 = metadata !{null, metadata !"align", i32 8, metadata !"align", i32 65544, metadata !"align", i32 131080}
!30 = metadata !{null, metadata !"align", i32 16}
!31 = metadata !{null, metadata !"align", i32 16, metadata !"align", i32 65552, metadata !"align", i32 131088}
!32 = metadata !{null, metadata !"align", i32 16, metadata !"align", i32 131088}
!33 = metadata !{null, metadata !"align", i32 16, metadata !"align", i32 131080}
!34 = metadata !{null, metadata !"align", i32 16, metadata !"align", i32 131088, metadata !"align", i32 196624, metadata !"align", i32 262160}
!35 = metadata !{null, metadata !"align", i32 16, metadata !"align", i32 131088, metadata !"align", i32 262160, metadata !"align", i32 327696}
!36 = metadata !{null, metadata !"align", i32 2}
!37 = metadata !{null, metadata !"align", i32 4}
!38 = metadata !{null, metadata !"align", i32 65538}
!39 = metadata !{null, metadata !"align", i32 65540}
!40 = metadata !{null, metadata !"align", i32 65544}
!41 = metadata !{null, metadata !"align", i32 65552}
!42 = metadata !{i32 721153, metadata !14, metadata !"a", metadata !15, i32 17, metadata !19, i32 0, i32 0} ; [ DW_TAG_arg_variable ]
!43 = metadata !{i32 17, i32 6, metadata !14, null}
!44 = metadata !{i32 721153, metadata !14, metadata !"b", metadata !15, i32 17, metadata !19, i32 0, i32 0} ; [ DW_TAG_arg_variable ]
!45 = metadata !{i32 721153, metadata !14, metadata !"c", metadata !15, i32 17, metadata !19, i32 0, i32 0} ; [ DW_TAG_arg_variable ]
!46 = metadata !{i32 721153, metadata !14, metadata !"N", metadata !15, i32 17, metadata !20, i32 0, i32 0} ; [ DW_TAG_arg_variable ]
!47 = metadata !{i32 17, i32 5, metadata !14, null}
!48 = metadata !{i32 19, i32 1, metadata !49, null}
!49 = metadata !{i32 720907, metadata !50, i32 17, i32 1, metadata !15, i32 2} ; [ DW_TAG_lexical_block ]
!50 = metadata !{i32 720907, metadata !51, i32 17, i32 1, metadata !15, i32 1} ; [ DW_TAG_lexical_block ]
!51 = metadata !{i32 720907, metadata !14, i32 17, i32 7, metadata !15, i32 0} ; [ DW_TAG_lexical_block ]
!52 = metadata !{i32 721152, metadata !49, metadata !"row", metadata !15, i32 19, metadata !20, i32 0, i32 0} ; [ DW_TAG_auto_variable ]
!53 = metadata !{i32 20, i32 1, metadata !49, null}
!54 = metadata !{i32 721152, metadata !49, metadata !"col", metadata !15, i32 20, metadata !20, i32 0, i32 0} ; [ DW_TAG_auto_variable ]
!55 = metadata !{i32 21, i32 1, metadata !49, null}
!56 = metadata !{i32 721152, metadata !49, metadata !"sum", metadata !15, i32 21, metadata !20, i32 0, i32 0} ; [ DW_TAG_auto_variable ]
!57 = metadata !{i32 22, i32 1, metadata !58, null}
!58 = metadata !{i32 720907, metadata !49, i32 21, i32 1, metadata !15, i32 3} ; [ DW_TAG_lexical_block ]
!59 = metadata !{i32 23, i32 1, metadata !60, null}
!60 = metadata !{i32 720907, metadata !61, i32 22, i32 1, metadata !15, i32 5} ; [ DW_TAG_lexical_block ]
!61 = metadata !{i32 720907, metadata !58, i32 22, i32 1, metadata !15, i32 4} ; [ DW_TAG_lexical_block ]
!62 = metadata !{i32 721152, metadata !60, metadata !"i", metadata !15, i32 23, metadata !20, i32 0, i32 0} ; [ DW_TAG_auto_variable ]
!63 = metadata !{i32 23, i32 1, metadata !64, null}
!64 = metadata !{i32 720907, metadata !60, i32 23, i32 1, metadata !15, i32 6} ; [ DW_TAG_lexical_block ]
!65 = metadata !{i32 24, i32 1, metadata !66, null}
!66 = metadata !{i32 720907, metadata !67, i32 23, i32 1, metadata !15, i32 8} ; [ DW_TAG_lexical_block ]
!67 = metadata !{i32 720907, metadata !64, i32 23, i32 1, metadata !15, i32 7} ; [ DW_TAG_lexical_block ]
!68 = metadata !{i32 23, i32 17, metadata !67, null}
!69 = metadata !{i32 26, i32 1, metadata !61, null}
!70 = metadata !{i32 28, i32 2, metadata !51, null}
