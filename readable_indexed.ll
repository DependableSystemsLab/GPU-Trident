; ModuleID = 'indexed.ll'
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v32:32:32-v64:64:64-v128:128:128-n16:32:64"
target triple = "nvptx-nvidia-cl.1.0"

@llvm.used = appending global [1 x i8*] [i8* bitcast (void (i32*, i32*, i32*, i32)* @_Z8gpu_multPiS_S_i to i8*)], section "llvm.metadata"

define void @_Z8gpu_multPiS_S_i(i32* %a, i32* %b, i32* %c, i32 %N) alwaysinline {
  call void @llvm.dbg.value(metadata !{i32* %a}, i64 0, metadata !42), !dbg !43
  call void @llvm.dbg.value(metadata !{i32* %b}, i64 0, metadata !44), !dbg !43
  call void @llvm.dbg.value(metadata !{i32* %c}, i64 0, metadata !45), !dbg !43
  call void @llvm.dbg.value(metadata !{i32 %N}, i64 0, metadata !46), !dbg !47
  call void @profileCount(i64 1)
  %1 = call i32 @llvm.nvvm.read.ptx.sreg.ctaid.y(), !dbg !48, !bamboo_index !52
  call void @profileCount(i64 2)
  %2 = call i32 @llvm.nvvm.read.ptx.sreg.ntid.y(), !dbg !48, !bamboo_index !53
  call void @profileCount(i64 3)
  %3 = mul i32 %1, %2, !dbg !48, !bamboo_index !54
  call void @profileCount(i64 4)
  %4 = call i32 @llvm.nvvm.read.ptx.sreg.tid.y(), !dbg !48, !bamboo_index !55
  call void @profileCount(i64 5)
  %5 = add i32 %3, %4, !dbg !48, !bamboo_index !56
  call void @llvm.dbg.value(metadata !{i32 %5}, i64 0, metadata !57), !dbg !48
  call void @profileCount(i64 6)
  %6 = call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !58, !bamboo_index !59
  call void @profileCount(i64 7)
  %7 = call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !58, !bamboo_index !60
  call void @profileCount(i64 8)
  %8 = mul i32 %6, %7, !dbg !58, !bamboo_index !61
  call void @profileCount(i64 9)
  %9 = call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !58, !bamboo_index !62
  call void @profileCount(i64 10)
  %10 = add i32 %8, %9, !dbg !58, !bamboo_index !63
  call void @llvm.dbg.value(metadata !{i32 %10}, i64 0, metadata !64), !dbg !58
  call void @profileCount(i64 11)
  %move = call i32 @llvm.nvvm.move.i32(i32 0), !dbg !65, !bamboo_index !66
  call void @llvm.dbg.value(metadata !{i32 %move}, i64 0, metadata !67), !dbg !65
  call void @profileCount(i64 12)
  %11 = icmp slt i32 %10, %N, !dbg !68, !bamboo_index !70
  call void @profileCount(i64 13)
  br i1 %11, label %12, label %14, !dbg !68, !bamboo_index !71

; <label>:12                                      ; preds = %0
  call void @profileCount(i64 14)
  %13 = icmp slt i32 %5, %N, !dbg !68, !bamboo_index !72
  call void @profileCount(i64 15)
  br label %14, !dbg !68, !bamboo_index !73

; <label>:14                                      ; preds = %12, %0
  %15 = phi i1 [ false, %0 ], [ %13, %12 ], !bamboo_index !74
  call void @profileCount(i64 17)
  br i1 %15, label %16, label %36, !dbg !68, !bamboo_index !75

; <label>:16                                      ; preds = %14
  call void @profileCount(i64 18)
  %move1 = call i32 @llvm.nvvm.move.i32(i32 0), !dbg !76, !bamboo_index !79
  call void @llvm.dbg.value(metadata !{i32 %move1}, i64 0, metadata !80), !dbg !76
  call void @profileCount(i64 19)
  br label %17, !dbg !81, !bamboo_index !83

; <label>:17                                      ; preds = %30, %16
  %__cuda_local_var_35607_6_non_const_sum.0 = phi i32 [ %move, %16 ], [ %29, %30 ], !dbg !81, !bamboo_index !84
  %i.0 = phi i32 [ %move1, %16 ], [ %31, %30 ], !dbg !81, !bamboo_index !85
  call void @llvm.dbg.value(metadata !{i32 %i.0}, i64 0, metadata !80)
  call void @profileCount(i64 22)
  %18 = icmp slt i32 %i.0, %N, !dbg !81, !bamboo_index !86
  call void @profileCount(i64 23)
  br i1 %18, label %19, label %32, !dbg !81, !bamboo_index !87

; <label>:19                                      ; preds = %17
  call void @profileCount(i64 24)
  %20 = mul nsw i32 %5, %N, !dbg !88, !bamboo_index !91
  call void @profileCount(i64 25)
  %21 = add nsw i32 %20, %i.0, !dbg !88, !bamboo_index !92
  call void @profileCount(i64 26)
  %22 = getelementptr inbounds i32* %a, i32 %21, !dbg !88, !bamboo_index !93
  call void @profileCount(i64 27)
  %23 = load i32* %22, align 4, !dbg !88, !bamboo_index !94
  call void @profileCount(i64 28)
  %24 = mul nsw i32 %i.0, %N, !dbg !88, !bamboo_index !95
  call void @profileCount(i64 29)
  %25 = add nsw i32 %24, %10, !dbg !88, !bamboo_index !96
  call void @profileCount(i64 30)
  %26 = getelementptr inbounds i32* %b, i32 %25, !dbg !88, !bamboo_index !97
  call void @profileCount(i64 31)
  %27 = load i32* %26, align 4, !dbg !88, !bamboo_index !98
  call void @profileCount(i64 32)
  %28 = mul nsw i32 %23, %27, !dbg !88, !bamboo_index !99
  call void @profileCount(i64 33)
  %29 = add nsw i32 %__cuda_local_var_35607_6_non_const_sum.0, %28, !dbg !88, !bamboo_index !100
  call void @llvm.dbg.value(metadata !{i32 %29}, i64 0, metadata !67), !dbg !88
  call void @profileCount(i64 34)
  br label %30, !dbg !101, !bamboo_index !102

; <label>:30                                      ; preds = %19
  call void @profileCount(i64 35)
  %31 = add nsw i32 %i.0, 1, !dbg !101, !bamboo_index !103
  call void @llvm.dbg.value(metadata !{i32 %31}, i64 0, metadata !80), !dbg !101
  call void @profileCount(i64 36)
  br label %17, !dbg !101, !bamboo_index !104

; <label>:32                                      ; preds = %17
  call void @profileCount(i64 37)
  %33 = mul nsw i32 %5, %N, !dbg !105, !bamboo_index !106
  call void @profileCount(i64 38)
  %34 = add nsw i32 %33, %10, !dbg !105, !bamboo_index !107
  call void @profileCount(i64 39)
  %35 = getelementptr inbounds i32* %c, i32 %34, !dbg !105, !bamboo_index !108
  call void @profileCount(i64 40)
  store i32 %__cuda_local_var_35607_6_non_const_sum.0, i32* %35, align 4, !dbg !105, !bamboo_index !109
  call void @profileCount(i64 41)
  br label %36, !dbg !105, !bamboo_index !110

; <label>:36                                      ; preds = %32, %14
  ret void, !dbg !111
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

declare void @profileCount(i64)

!llvm.dbg.cu = !{!0}
!nvvm.annotations = !{!27, !28, !29, !28, !30, !30, !30, !30, !31, !31, !30, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !33, !33, !33, !33, !33, !33, !33, !33, !33, !33, !33, !33, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !32, !34, !34, !34, !35, !35, !35, !34, !34, !34, !35, !35, !35, !34, !34, !34, !36, !37, !37, !28, !28, !30, !30, !36, !37, !37, !28, !28, !30, !30, !36, !37, !37, !28, !28, !30, !30, !36, !37, !37, !28, !28, !30, !30, !36, !37, !37, !28, !28, !30, !30, !38, !39, !39, !40, !40, !41, !41, !38, !39, !39, !40, !40, !41, !41, !38, !39, !39, !40, !40, !41, !41, !38, !39, !39, !40, !40, !41, !41, !38, !39, !39, !40, !40, !41, !41}
!nvvm.internalize.after.link = !{}

!0 = metadata !{i32 720913, i32 0, i32 4, metadata !"example.cu", metadata !"/home/abdul/GPU-Trident/GPU-Trident-mem", metadata !"lgenfe: EDG 4.1", i1 true, i1 false, metadata !"", i32 0, metadata !1, metadata !3, metadata !12, metadata !1} ; [ DW_TAG_compile_unit ]
!1 = metadata !{metadata !2}
!2 = metadata !{i32 0}
!3 = metadata !{metadata !4}
!4 = metadata !{metadata !5}
!5 = metadata !{i32 720915, metadata !6, metadata !"dim3", metadata !6, i32 415, i64 96, i64 32, i32 0, i32 0, i32 0, metadata !7, i32 0, i32 0} ; [ DW_TAG_structure_type ]
!6 = metadata !{i32 720937, metadata !"/usr/local/cuda-6.0/bin/..//include/vector_types.h", metadata !"/home/abdul/GPU-Trident/GPU-Trident-mem", null} ; [ DW_TAG_file_type ]
!7 = metadata !{metadata !8, metadata !10, metadata !11}
!8 = metadata !{i32 720909, metadata !6, metadata !"x", metadata !6, i32 417, i64 32, i64 32, i64 0, i32 0, metadata !9} ; [ DW_TAG_member ]
!9 = metadata !{i32 720932, null, metadata !"unsigned int", null, i32 0, i64 32, i64 32, i64 0, i32 0, i32 7} ; [ DW_TAG_base_type ]
!10 = metadata !{i32 720909, metadata !6, metadata !"y", metadata !6, i32 417, i64 32, i64 32, i64 32, i32 0, metadata !9} ; [ DW_TAG_member ]
!11 = metadata !{i32 720909, metadata !6, metadata !"z", metadata !6, i32 417, i64 32, i64 32, i64 64, i32 0, metadata !9} ; [ DW_TAG_member ]
!12 = metadata !{metadata !13}
!13 = metadata !{metadata !14, metadata !21, metadata !26}
!14 = metadata !{i32 720942, i32 0, metadata !15, metadata !"_Z8gpu_multPiS_S_i", metadata !"_Z8gpu_multPiS_S_i", metadata !"_Z8gpu_multPiS_S_i", metadata !15, i32 17, metadata !16, i1 false, i1 true, i32 0, i32 0, i32 0, i32 0, i1 false, void (i32*, i32*, i32*, i32)* @_Z8gpu_multPiS_S_i, null, null, metadata !1} ; [ DW_TAG_subprogram ]
!15 = metadata !{i32 720937, metadata !"example.cu", metadata !"/home/abdul/GPU-Trident/GPU-Trident-mem", null} ; [ DW_TAG_file_type ]
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
!52 = metadata !{metadata !"1"}
!53 = metadata !{metadata !"2"}
!54 = metadata !{metadata !"3"}
!55 = metadata !{metadata !"4"}
!56 = metadata !{metadata !"5"}
!57 = metadata !{i32 721152, metadata !49, metadata !"row", metadata !15, i32 19, metadata !20, i32 0, i32 0} ; [ DW_TAG_auto_variable ]
!58 = metadata !{i32 20, i32 1, metadata !49, null}
!59 = metadata !{metadata !"6"}
!60 = metadata !{metadata !"7"}
!61 = metadata !{metadata !"8"}
!62 = metadata !{metadata !"9"}
!63 = metadata !{metadata !"10"}
!64 = metadata !{i32 721152, metadata !49, metadata !"col", metadata !15, i32 20, metadata !20, i32 0, i32 0} ; [ DW_TAG_auto_variable ]
!65 = metadata !{i32 21, i32 1, metadata !49, null}
!66 = metadata !{metadata !"11"}
!67 = metadata !{i32 721152, metadata !49, metadata !"sum", metadata !15, i32 21, metadata !20, i32 0, i32 0} ; [ DW_TAG_auto_variable ]
!68 = metadata !{i32 22, i32 1, metadata !69, null}
!69 = metadata !{i32 720907, metadata !49, i32 21, i32 1, metadata !15, i32 3} ; [ DW_TAG_lexical_block ]
!70 = metadata !{metadata !"12"}
!71 = metadata !{metadata !"13"}
!72 = metadata !{metadata !"14"}
!73 = metadata !{metadata !"15"}
!74 = metadata !{metadata !"16"}
!75 = metadata !{metadata !"17"}
!76 = metadata !{i32 23, i32 1, metadata !77, null}
!77 = metadata !{i32 720907, metadata !78, i32 22, i32 1, metadata !15, i32 5} ; [ DW_TAG_lexical_block ]
!78 = metadata !{i32 720907, metadata !69, i32 22, i32 1, metadata !15, i32 4} ; [ DW_TAG_lexical_block ]
!79 = metadata !{metadata !"18"}
!80 = metadata !{i32 721152, metadata !77, metadata !"i", metadata !15, i32 23, metadata !20, i32 0, i32 0} ; [ DW_TAG_auto_variable ]
!81 = metadata !{i32 23, i32 1, metadata !82, null}
!82 = metadata !{i32 720907, metadata !77, i32 23, i32 1, metadata !15, i32 6} ; [ DW_TAG_lexical_block ]
!83 = metadata !{metadata !"19"}
!84 = metadata !{metadata !"20"}
!85 = metadata !{metadata !"21"}
!86 = metadata !{metadata !"22"}
!87 = metadata !{metadata !"23"}
!88 = metadata !{i32 24, i32 1, metadata !89, null}
!89 = metadata !{i32 720907, metadata !90, i32 23, i32 1, metadata !15, i32 8} ; [ DW_TAG_lexical_block ]
!90 = metadata !{i32 720907, metadata !82, i32 23, i32 1, metadata !15, i32 7} ; [ DW_TAG_lexical_block ]
!91 = metadata !{metadata !"24"}
!92 = metadata !{metadata !"25"}
!93 = metadata !{metadata !"26"}
!94 = metadata !{metadata !"27"}
!95 = metadata !{metadata !"28"}
!96 = metadata !{metadata !"29"}
!97 = metadata !{metadata !"30"}
!98 = metadata !{metadata !"31"}
!99 = metadata !{metadata !"32"}
!100 = metadata !{metadata !"33"}
!101 = metadata !{i32 23, i32 17, metadata !90, null}
!102 = metadata !{metadata !"34"}
!103 = metadata !{metadata !"35"}
!104 = metadata !{metadata !"36"}
!105 = metadata !{i32 26, i32 1, metadata !78, null}
!106 = metadata !{metadata !"37"}
!107 = metadata !{metadata !"38"}
!108 = metadata !{metadata !"39"}
!109 = metadata !{metadata !"40"}
!110 = metadata !{metadata !"41"}
!111 = metadata !{i32 28, i32 2, metadata !51, null}
